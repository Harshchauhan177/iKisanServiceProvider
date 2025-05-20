import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var otp = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var showingOTPAlert = false

    var body: some View {
        VStack(spacing: 20) {
            ScrollView {
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 30)
                
                TextField("Full Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                    .disabled(dataController.isOTPSent)
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .disabled(dataController.isOTPSent)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(dataController.isOTPSent)
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(dataController.isOTPSent)
                
                if !dataController.isOTPSent {
                    Button(action: initiateSignUp) {
                        Text("Sign Up")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .disabled(name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty)
                }
            }
            .padding(.horizontal)
            
            Button(action: goToLogin) {
                Text("Already have an account? Login")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .loading(isLoading)
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .alert("Enter OTP", isPresented: $showingOTPAlert) {
            TextField("Enter OTP", text: $otp)
                .keyboardType(.numberPad)
            Button("Cancel", role: .cancel) {
                otp = ""
            }
            Button("Verify") {
                verifyOTP()
            }
        } message: {
            Text("Please enter the OTP sent to your email")
        }
    }
    
    private func initiateSignUp() {
        guard !name.isEmpty else {
            alertMessage = "Please enter your name"
            showingAlert = true
            return
        }
        
        guard !email.isEmpty else {
            alertMessage = "Please enter your email"
            showingAlert = true
            return
        }
        
        guard password == confirmPassword else {
            alertMessage = "Passwords do not match"
            showingAlert = true
            return
        }
        
        isLoading = true
        Task {
            do {
                try await dataController.sendOTP(email: email, name: name, password: password)
                DispatchQueue.main.async {
                    isLoading = false
                    showingOTPAlert = true
                }
            } catch {
                DispatchQueue.main.async {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                    isLoading = false
                }
            }
        }
    }
    
    private func verifyOTP() {
        guard !otp.isEmpty else { return }
        
        isLoading = true
        Task {
            do {
                try await dataController.verifyOTP(otp: otp)
                try await dataController.completeSignUp()
                DispatchQueue.main.async {
                    alertMessage = "Account created successfully!"
                    showingAlert = true
                    isLoading = false
                    dismiss() // go back to login
                }
            } catch {
                DispatchQueue.main.async {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                    isLoading = false
                }
            }
        }
    }
    
    private func goToLogin() {
        dismiss()
    }
}
