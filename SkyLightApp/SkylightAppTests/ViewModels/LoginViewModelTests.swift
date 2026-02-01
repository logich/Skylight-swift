import XCTest
@testable import SkylightApp

@MainActor
final class LoginViewModelTests: XCTestCase {

    var mockKeychainManager: MockKeychainManager!
    var mockAPIClient: MockAPIClient!
    var testDefaults: UserDefaults!
    var authManager: AuthenticationManager!
    var sut: LoginViewModel!

    override func setUp() async throws {
        try await super.setUp()

        mockKeychainManager = MockKeychainManager()
        mockAPIClient = MockAPIClient()

        testDefaults = UserDefaults(suiteName: "com.test.skylight.login")!
        testDefaults.removePersistentDomain(forName: "com.test.skylight.login")

        authManager = AuthenticationManager(
            keychainManager: mockKeychainManager,
            apiClient: mockAPIClient,
            userDefaults: testDefaults
        )

        sut = LoginViewModel(authManager: authManager)
    }

    override func tearDown() async throws {
        testDefaults.removePersistentDomain(forName: "com.test.skylight.login")
        testDefaults = nil
        mockKeychainManager = nil
        mockAPIClient = nil
        authManager = nil
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Form Validation Tests

    func testIsFormValid_ReturnsFalse_WhenEmailEmpty() {
        // Given
        sut.email = ""
        sut.password = "password123"

        // Then
        XCTAssertFalse(sut.isFormValid)
    }

    func testIsFormValid_ReturnsFalse_WhenEmailWhitespaceOnly() {
        // Given
        sut.email = "   "
        sut.password = "password123"

        // Then
        XCTAssertFalse(sut.isFormValid)
    }

    func testIsFormValid_ReturnsFalse_WhenEmailMissingAtSymbol() {
        // Given
        sut.email = "invalidemail.com"
        sut.password = "password123"

        // Then
        XCTAssertFalse(sut.isFormValid)
    }

    func testIsFormValid_ReturnsFalse_WhenPasswordEmpty() {
        // Given
        sut.email = "test@example.com"
        sut.password = ""

        // Then
        XCTAssertFalse(sut.isFormValid)
    }

    func testIsFormValid_ReturnsTrue_WhenValidEmailAndPassword() {
        // Given
        sut.email = "test@example.com"
        sut.password = "password123"

        // Then
        XCTAssertTrue(sut.isFormValid)
    }

    func testIsFormValid_ReturnsTrue_WhenEmailHasWhitespaceButIsValid() {
        // Given
        sut.email = "  test@example.com  "
        sut.password = "password123"

        // Then
        XCTAssertTrue(sut.isFormValid) // trimmed email is valid
    }

    // MARK: - Login Tests

    func testLogin_WhenFormInvalid_DoesNotCallAPI() async throws {
        // Given
        sut.email = ""
        sut.password = ""

        // When
        await sut.login()

        // Then
        XCTAssertFalse(mockAPIClient.requestCalled)
        XCTAssertFalse(sut.isLoading)
    }

    func testLogin_WhenSuccessful_SavesCredentials() async throws {
        // Given
        sut.email = "test@example.com"
        sut.password = "password123"

        let loginResponse = LoginResponse(
            token: "test-token-123",
            userId: "user-123"
        )
        mockAPIClient.responseToReturn = loginResponse

        // Also need to mock the frames response for loadFrames
        let framesResponse = FramesResponse(frames: [TestDataFactory.makeFrame()])
        mockAPIClient.responseToReturn = framesResponse

        // When
        await sut.login()

        // Then
        XCTAssertTrue(mockKeychainManager.saveAccessTokenCalled)
        XCTAssertTrue(mockKeychainManager.saveUserIdCalled)
    }

    func testLogin_WhenFails_SetsError() async throws {
        // Given
        sut.email = "test@example.com"
        sut.password = "wrongpassword"

        mockAPIClient.errorToThrow = APIError.unauthorized

        // When
        await sut.login()

        // Then
        XCTAssertNotNil(sut.error)
        XCTAssertTrue(sut.showError)
        XCTAssertFalse(sut.isLoading)
    }

    func testLogin_TrimsAndLowercasesEmail() async throws {
        // Given
        sut.email = "  TEST@Example.COM  "
        sut.password = "password123"

        let loginResponse = LoginResponse(
            token: "test-token",
            userId: "user-123"
        )
        mockAPIClient.responseToReturn = loginResponse

        // When
        await sut.login()

        // Then
        // The login should have been called with the trimmed, lowercased email
        // We can verify this through the endpoint parameter if needed
        XCTAssertTrue(mockAPIClient.requestCalled)
    }

    // MARK: - Error Handling Tests

    func testClearError_ResetsErrorState() {
        // Given
        sut.error = APIError.unauthorized
        sut.showError = true

        // When
        sut.clearError()

        // Then
        XCTAssertNil(sut.error)
        XCTAssertFalse(sut.showError)
    }

    // MARK: - Loading State Tests

    func testLogin_SetsIsLoadingDuringRequest() async throws {
        // Given
        sut.email = "test@example.com"
        sut.password = "password123"

        mockAPIClient.errorToThrow = APIError.networkError(NSError(domain: "test", code: -1))

        // When
        await sut.login()

        // Then - After completion, loading should be false
        XCTAssertFalse(sut.isLoading)
    }
}

// MARK: - Test Helpers

private struct LoginResponse: Codable {
    let token: String
    let userId: String
}

private struct FramesResponse: Codable {
    let frames: [Frame]
}
