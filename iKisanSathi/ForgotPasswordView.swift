//
//  ForgotPasswordView.swift
//  iKisanSathi
//
//  Created on 04/12/25.
//

import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var otp = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    @State private var currentStep = 1 // 1: Email, 2: OTP, 3: New Password
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Error"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Progress Indicator
                    HStack(spacing: 10) {
                        ForEach(1...3, id: \.self) { step in
                            Circle()
                                .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 12, height: 12)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Header
                    VStack(spacing: 8) {
                        Text(stepTitle)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(stepDescription)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 20)
                    
                    // Step Content
                    Group {
                        switch currentStep {
                        case 1:
                            emailStepView
                        case 2:
                            otpStepView
                        case 3:
                            passwordStepView
                        default:
                            EmptyView()
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .loading(isLoading)
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Step 1: Email Input
    
    private var emailStepView: some View {
        VStack(spacing: 20) {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .disabled(isLoading)
            
            Button(action: sendOTP) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text(isLoading ? "Sending..." : "Send OTP")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(email.isEmpty ? Color.gray : Color.blue)
                .cornerRadius(10)
            }
            .disabled(email.isEmpty || isLoading)
        }
    }
    
    // MARK: - Step 2: OTP Verification
    
    private var otpStepView: some View {
        VStack(spacing: 20) {
            TextField("Enter OTP", text: $otp)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .disabled(isLoading)
            
            Text("Please check your email for the verification code")
                .font(.caption)
                .foregroundColor(.gray)
            
            Button(action: verifyOTP) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text(isLoading ? "Verifying..." : "Verify OTP")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(otp.isEmpty ? Color.gray : Color.blue)
                .cornerRadius(10)
            }
            .disabled(otp.isEmpty || isLoading)
            
            Button(action: resendOTP) {
                Text("Resend OTP")
                    .foregroundColor(.blue)
                    .underline()
            }
            .disabled(isLoading)
        }
    }
    
    // MARK: - Step 3: New Password
    
    private var passwordStepView: some View {
        VStack(spacing: 20) {
            SecureField("New Password", text: $newPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(isLoading)
            
            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(isLoading)
            
            if !newPassword.isEmpty && !confirmPassword.isEmpty && newPassword != confirmPassword {
                Text("Passwords do not match")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            if !newPassword.isEmpty && newPassword.count < 6 {
                Text("Password must be at least 6 characters")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Button(action: resetPassword) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text(isLoading ? "Resetting..." : "Reset Password")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isPasswordValid ? Color.blue : Color.gray)
                .cornerRadius(10)
            }
            .disabled(!isPasswordValid || isLoading)
        }
    }
    
    // MARK: - Helper Properties
    
    private var stepTitle: String {
        switch currentStep {
        case 1: return "Enter Your Email"
        case 2: return "Verify OTP"
        case 3: return "Create New Password"
        default: return ""
        }
    }
    
    private var stepDescription: String {
        switch currentStep {
        case 1: return "We'll send you a verification code"
        case 2: return "Enter the 6-digit code sent to your email"
        case 3: return "Choose a strong password for your account"
        default: return ""
        }
    }
    
    private var isPasswordValid: Bool {
        !newPassword.isEmpty &&
        !confirmPassword.isEmpty &&
        newPassword == confirmPassword &&
        newPassword.count >= 6
    }
    
    // MARK: - Actions
    
    private func sendOTP() {
        guard !email.isEmpty else { return }
        
        isLoading = true
        Task {
            do {
                try await dataController.sendPasswordResetOTP(email: email)
                DispatchQueue.main.async {
                    isLoading = false
                    currentStep = 2
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    alertTitle = "Error"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
    
    private func verifyOTP() {
        guard !otp.isEmpty else { return }
        
        isLoading = true
        Task {
            do {
                try await dataController.verifyPasswordResetOTP(otp: otp)
                DispatchQueue.main.async {
                    isLoading = false
                    currentStep = 3
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    alertTitle = "Error"
                    alertMessage = "Invalid OTP. Please try again."
                    showingAlert = true
                }
            }
        }
    }
    
    private func resendOTP() {
        otp = ""
        sendOTP()
    }
    
    private func resetPassword() {
        guard isPasswordValid else { return }
        
        isLoading = true
        Task {
            do {
                try await dataController.resetPassword(newPassword: newPassword)
                DispatchQueue.main.async {
                    isLoading = false
                    alertTitle = "Success"
                    alertMessage = "Your password has been reset successfully. Please login with your new password."
                    showingAlert = true
                    
                    // Dismiss after showing success message
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        dismiss()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    alertTitle = "Error"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

#Preview {
    ForgotPasswordView()
        .environmentObject(DataController())
}
