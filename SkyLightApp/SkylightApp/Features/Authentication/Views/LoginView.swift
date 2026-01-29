import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @FocusState private var focusedField: Field?

    private enum Field {
        case email
        case password
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    headerSection

                    loginForm

                    Spacer(minLength: 40)

                    disclaimerText
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
            }
            .background(Color(.systemGroupedBackground))
            .ignoresSafeArea(.keyboard)
            .onTapGesture {
                focusedField = nil
            }
            .alert("Login Failed", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "An unknown error occurred")
            }
            .loadingOverlay(isLoading: viewModel.isLoading)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 70))
                .foregroundStyle(.blue)
                .symbolRenderingMode(.hierarchical)

            Text("Skylight")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Sign in to access your family calendar")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var loginForm: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                TextField("your@email.com", text: $viewModel.email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .password
                    }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                SecureField("Enter your password", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .onSubmit {
                        if viewModel.isFormValid {
                            Task {
                                await viewModel.login()
                            }
                        }
                    }
            }

            Button {
                Task {
                    await viewModel.login()
                }
            } label: {
                Text("Sign In")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isFormValid || viewModel.isLoading)
            .padding(.top, 8)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
    }

    private var disclaimerText: some View {
        Text("This is an unofficial app using a reverse-engineered API. Use at your own risk.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
}

#Preview {
    LoginView()
}
