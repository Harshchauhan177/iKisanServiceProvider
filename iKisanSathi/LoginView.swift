import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var dataController: DataController
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @StateObject private var appleVM = SignInWithAppleViewModel()
    
    var body: some View {
        Group {
            if appleVM.isAuthenticated && appleVM.navigateToHome {
                MainTabView()
            } else {
                VStack {
                    VStack(spacing: 20) {
                        Text("Producer Login")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.bottom, 30)
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: login) {
                            Text("Login")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        
                        Button(action: { showingSignUp = true }) {
                            Text("Don't have an account? Sign Up")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    
                    NavigationLink(isActive: $showingSignUp) {
                        SignUpView()
                    } label: {
                        EmptyView()
                    }
                    
                    .padding()
                    .loading(isLoading)
                    .alert("Error", isPresented: $showingAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text(alertMessage)
                    }
                    
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
                    .padding()
                }
            }
        }
        .sheet(isPresented: $appleVM.showProfileCompletion) {
            ProfileCompletionView(userEmail: appleVM.pendingUserEmail, viewModel: appleVM)
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
