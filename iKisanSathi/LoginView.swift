import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var dataController: DataController
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    @State private var showingForgotPassword = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @StateObject private var appleVM = SignInWithAppleViewModel()
    
    var body: some View {
        Group {
            if appleVM.isAuthenticated && appleVM.navigateToHome {
                MainTabView()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // App Logo and Name Section
                        VStack(spacing: 16) {
                            Image("iKisan")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                            
                            Text("iKisanSathi")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .padding(.top, 60)
                        .padding(.bottom, 50)
                        
                        // Login Form Section
                        VStack(spacing: 16) {
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                TextField("Enter your email", text: $email)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                SecureField("Enter your password", text: $password)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .textContentType(.password)
                            }
                            
                            // Forgot Password Button
                            HStack {
                                Spacer()
                                Button(action: { showingForgotPassword = true }) {
                                    Text("Forgot Password?")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            }
                            .padding(.top, 4)
                            
                            // Login Button
                            Button(action: login) {
                                Text("Log In")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                    .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .padding(.top, 8)
                            .disabled(isLoading)
                            
                            // Divider with "or"
                            HStack {
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.3))
                                    .frame(height: 1)
                                
                                Text("or")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.vertical, 16)
                            
                            // Sign in with Apple Button
                            SignInWithAppleButton(.signIn, onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            }, onCompletion: { result in
                                switch result {
                                case .success(let authResults):
                                    if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
                                        Task {
                                            await appleVM.handleAppleSignIn(credential: appleIDCredential)
                                            // Don't set session in DataController until profile is completed
                                            // This will be handled in the ProfileCompletionView when user submits
                                        }
                                    }
                                case .failure(let error):
                                    appleVM.errorMessage = error.localizedDescription
                                }
                            })
                            .signInWithAppleButtonStyle(.black)
                            .frame(height: 50)
                            .cornerRadius(12)
                            
                            // Sign Up Link
                            HStack {
                                Text("Don't have an account?")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Button(action: { showingSignUp = true }) {
                                    Text("Sign Up")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .padding(.top, 16)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
                .background(Color(.systemGroupedBackground))
                .navigationBarHidden(true)
                
                // Hidden Navigation Links
                NavigationLink(isActive: $showingSignUp) {
                    SignUpView()
                } label: {
                    EmptyView()
                }
            }
        }
        .loading(isLoading)
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $appleVM.showProfileCompletion) {
            ProfileCompletionView(userEmail: appleVM.pendingUserEmail, viewModel: appleVM)
        }
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordView()
                .environmentObject(dataController)
        }
        .onChange(of: appleVM.navigateToHome) { navigateToHome in
            if navigateToHome && appleVM.isAuthenticated {
                // When navigating to home for existing users, set session in DataController
                if let session = appleVM.lastSupabaseSession {
                    Task {
                        await dataController.setSessionFromApple(session: session)
                    }
                }
            }
        }
        .onChange(of: appleVM.errorMessage) { newValue in
            if let error = newValue {
                alertMessage = error
                showingAlert = true
            }
        }
    }
    
    private func login() {
        isLoading = true
        Task {
            do {
                try await dataController.signIn(email: email, password: password)
            } catch {
                alertMessage = error.localizedDescription
                showingAlert = true
            }
            isLoading = false
        }
    }
}
