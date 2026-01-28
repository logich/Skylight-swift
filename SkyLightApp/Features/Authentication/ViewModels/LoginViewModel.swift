import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var showError: Bool = false

    private let authManager: AuthenticationManager

    var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty &&
        email.contains("@")
    }

    init(authManager: AuthenticationManager = .shared) {
        self.authManager = authManager
    }

    func login() async {
        guard isFormValid else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await authManager.login(
                email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                password: password
            )
        } catch {
            self.error = error
            self.showError = true
        }
    }

    func clearError() {
        error = nil
        showError = false
    }
}
