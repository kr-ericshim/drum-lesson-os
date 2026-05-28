import SwiftUI

struct LoginView: View {
    @Bindable var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 8) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                Text("Drum Lesson OS")
                    .font(.largeTitle.bold())
                Text("Sign in to open the native lesson workbench.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            WorkbenchPanel {
                VStack(alignment: .leading, spacing: 14) {
                    TextField("Email", text: $viewModel.email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.username)
                        .accessibilityLabel("Email")

                    SecureField("Password", text: $viewModel.password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                        .accessibilityLabel("Password")

                    if let message = viewModel.errorMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(message.contains("opened") ? Color.secondary : Color.red)
                    }

                    HStack {
                        Button("Forgot Password") {
                            Task { await viewModel.recoverPassword() }
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button {
                            Task { await viewModel.signIn() }
                        } label: {
                            Label(viewModel.isLoading ? "Signing In" : "Sign In", systemImage: "arrow.right.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isLoading)
                    }
                }
            }
            .frame(width: 420)
        }
        .padding(32)
    }
}
