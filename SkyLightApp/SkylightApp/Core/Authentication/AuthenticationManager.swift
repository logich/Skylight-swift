import Foundation
import Combine

enum AuthState: Equatable {
    case unauthenticated
    case authenticated
    case frameSelected
}

@MainActor
final class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()

    @Published private(set) var authState: AuthState = .unauthenticated
    @Published private(set) var currentUser: User?
    @Published private(set) var availableFrames: [Frame] = []
    @Published private(set) var currentFrame: Frame?

    private let keychainManager: KeychainManagerProtocol
    private let apiClient: APIClientProtocol
    private let userDefaults: UserDefaults

    var isAuthenticated: Bool {
        authState != .unauthenticated
    }

    var currentFrameId: String? {
        currentFrame?.id ?? userDefaults.string(forKey: Constants.UserDefaults.selectedFrameIdKey)
    }

    init(
        keychainManager: KeychainManagerProtocol = KeychainManager.shared,
        apiClient: APIClientProtocol = APIClient.shared,
        userDefaults: UserDefaults = .standard
    ) {
        self.keychainManager = keychainManager
        self.apiClient = apiClient
        self.userDefaults = userDefaults

        checkExistingAuth()
    }

    private func checkExistingAuth() {
        guard keychainManager.getAccessToken() != nil else {
            authState = .unauthenticated
            return
        }

        if let frameId = userDefaults.string(forKey: Constants.UserDefaults.selectedFrameIdKey) {
            authState = .frameSelected
            Task {
                await loadFrameInfo(frameId: frameId)
            }
        } else {
            authState = .authenticated
            Task {
                await loadFrames()
            }
        }
    }

    func login(email: String, password: String) async throws {
        let endpoint = SkylightEndpoint.login(email: email, password: password)
        let response: LoginResponse = try await apiClient.request(endpoint)

        _ = keychainManager.saveAccessToken(response.token)
        _ = keychainManager.saveUserId(response.userId)

        // User details will be loaded with frames
        authState = .authenticated

        await loadFrames()
    }

    func logout() {
        keychainManager.clearAll()
        userDefaults.removeObject(forKey: Constants.UserDefaults.selectedFrameIdKey)
        userDefaults.removeObject(forKey: Constants.UserDefaults.selectedFrameNameKey)

        currentUser = nil
        currentFrame = nil
        availableFrames = []
        authState = .unauthenticated
    }

    func selectFrame(_ frame: Frame) {
        currentFrame = frame
        userDefaults.set(frame.id, forKey: Constants.UserDefaults.selectedFrameIdKey)
        userDefaults.set(frame.name, forKey: Constants.UserDefaults.selectedFrameNameKey)
        authState = .frameSelected
    }

    func clearFrameSelection() {
        currentFrame = nil
        userDefaults.removeObject(forKey: Constants.UserDefaults.selectedFrameIdKey)
        userDefaults.removeObject(forKey: Constants.UserDefaults.selectedFrameNameKey)
        authState = .authenticated
    }

    private func loadFrames() async {
        // Load user info and frames in parallel
        async let userTask: () = loadUserInfo()
        async let framesTask = fetchFrames()

        _ = await userTask
        let frames = await framesTask

        availableFrames = frames

        if frames.count == 1, let frame = frames.first {
            selectFrame(frame)
        }
    }

    private func loadUserInfo() async {
        do {
            let endpoint = SkylightEndpoint.getCurrentUser
            let response: UserResponse = try await apiClient.request(endpoint)
            currentUser = response.user
        } catch {
            #if DEBUG
            print("Failed to load user info: \(error)")
            #endif
        }
    }

    private func fetchFrames() async -> [Frame] {
        do {
            let endpoint = SkylightEndpoint.getFrames
            let response: FramesResponse = try await apiClient.request(endpoint)
            return response.frames
        } catch {
            #if DEBUG
            print("Failed to fetch frames: \(error)")
            #endif
            return []
        }
    }

    private func loadFrameInfo(frameId: String) async {
        do {
            let endpoint = SkylightEndpoint.getFrame(frameId: frameId)
            let response: FrameResponse = try await apiClient.request(endpoint)
            currentFrame = response.frame
        } catch {
            #if DEBUG
            print("Failed to load frame info: \(error)")
            #endif
        }
    }

    func refreshTokenIfNeeded() async throws {
        // The Skylight API doesn't have a dedicated token refresh endpoint
        // If the token expires, the user needs to log in again
        guard keychainManager.getAccessToken() != nil else {
            throw APIError.unauthorized
        }
    }
}
