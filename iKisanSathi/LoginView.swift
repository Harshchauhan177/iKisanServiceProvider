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
            if appleVM.isAuthenticated {
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
                                    if let session = appleVM.lastSupabaseSession {
                                        await dataController.setSessionFromApple(session: session)
                                    }
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
