import CoreLocation
import MapKit

/// Service for location-related operations including geocoding and directions
@MainActor
final class LocationService: NSObject {
    static let shared = LocationService()

    private let locationManager = CLLocationManager()

    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    // MARK: - Current Location

    /// Requests the user's current location
    /// Returns the location or throws an error if unavailable
    func getCurrentLocation() async throws -> CLLocation {
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            // Wait a moment for the user to respond
            try await Task.sleep(nanoseconds: 500_000_000)
            return try await getCurrentLocation()

        case .restricted, .denied:
            throw LocationError.permissionDenied

        case .authorizedWhenInUse, .authorizedAlways:
            break

        @unknown default:
            throw LocationError.permissionDenied
        }

        // Request location
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            locationManager.requestLocation()
        }
    }

    // MARK: - Location Search

    /// Searches for locations matching the query
    func searchLocations(query: String) async throws -> [LocationSearchResult] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return []
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        // Bias results towards user's current region if available
        if let location = locationManager.location {
            let region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 50000,
                longitudinalMeters: 50000
            )
            request.region = region
        }

        let search = MKLocalSearch(request: request)
        let response = try await search.start()

        return response.mapItems.map { mapItem in
            LocationSearchResult(
                name: mapItem.name ?? "",
                address: mapItem.placemark.formattedAddress,
                coordinate: mapItem.placemark.coordinate
            )
        }
    }

    // MARK: - Geocoding

    /// Converts an address string to coordinates using MKLocalSearch
    func geocode(address: String) async throws -> CLLocationCoordinate2D {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = address

        let search = MKLocalSearch(request: request)
        let response = try await search.start()

        guard let coordinate = response.mapItems.first?.placemark.coordinate else {
            throw LocationError.geocodingFailed
        }

        return coordinate
    }

    // MARK: - Directions

    /// Calculates driving time between two locations
    /// Returns the travel time in minutes
    func getDrivingTime(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> Int {
        let request = MKDirections.Request()

        // Use location-based MKMapItem initializer (iOS 18+)
        let originLocation = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)

        if #available(iOS 26.0, *) {
            request.source = MKMapItem(location: originLocation, address: nil)
        } else {
            // Fallback on earlier versions
        }
        if #available(iOS 26.0, *) {
            request.destination = MKMapItem(location: destinationLocation, address: nil)
        } else {
            // Fallback on earlier versions
        }
        request.transportType = .automobile
        request.requestsAlternateRoutes = false

        let directions = MKDirections(request: request)

        do {
            let response = try await directions.calculate()

            guard let route = response.routes.first else {
                throw LocationError.noRouteFound
            }

            // Convert seconds to minutes
            return Int(route.expectedTravelTime / 60)
        } catch let error as MKError {
            switch error.code {
            case .directionsNotFound:
                throw LocationError.noRouteFound
            default:
                throw LocationError.directionsUnavailable
            }
        }
    }

    /// Calculates driving time from current location to an address
    func getDrivingTimeToAddress(_ address: String) async throws -> Int {
        let currentLocation = try await getCurrentLocation()
        let destination = try await geocode(address: address)

        return try await getDrivingTime(
            from: currentLocation.coordinate,
            to: destination
        )
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }

        Task { @MainActor in
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            locationContinuation?.resume(throwing: LocationError.locationUnavailable)
            locationContinuation = nil
        }
    }
}

// MARK: - Errors

// MARK: - Location Search Result

struct LocationSearchResult: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D

    var displayText: String {
        if name.isEmpty {
            return address
        } else if address.isEmpty {
            return name
        } else {
            return "\(name), \(address)"
        }
    }

    static func == (lhs: LocationSearchResult, rhs: LocationSearchResult) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - CLPlacemark Extension

extension CLPlacemark {
    var formattedAddress: String {
        var components: [String] = []

        if let street = thoroughfare {
            if let number = subThoroughfare {
                components.append("\(number) \(street)")
            } else {
                components.append(street)
            }
        }

        if let city = locality {
            components.append(city)
        }

        if let state = administrativeArea {
            components.append(state)
        }

        return components.joined(separator: ", ")
    }
}

enum LocationError: Error, CustomLocalizedStringResourceConvertible {
    case permissionDenied
    case locationUnavailable
    case geocodingFailed
    case noRouteFound
    case directionsUnavailable
    case noLocationOnEvent

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .permissionDenied:
            return "Location permission is required. Please enable it in Settings."
        case .locationUnavailable:
            return "Unable to get your current location."
        case .geocodingFailed:
            return "Could not find the event location on the map."
        case .noRouteFound:
            return "No driving route found to the event location."
        case .directionsUnavailable:
            return "Driving directions are not available for this route."
        case .noLocationOnEvent:
            return "The next event does not have a location."
        }
    }
}
