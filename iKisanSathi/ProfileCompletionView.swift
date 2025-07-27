//
//  ProfileCompletionView.swift
//  iKisanSathi
//
//  Created by Anshu Nagar on 27/07/25.
//

import SwiftUI

struct ProfileCompletionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataController: DataController
    @StateObject private var viewModel: SignInWithAppleViewModel
    @State private var fullName: String = ""
    @State private var mobileNumber: String = ""
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    let userEmail: String
    
    init(userEmail: String, viewModel: SignInWithAppleViewModel) {
        self.userEmail = userEmail
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo
                    Image("iKisan")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .accessibilityLabel("iKisan Logo")
                    
                    // Title
                    Text("Complete Your Profile")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    // Subtitle
                    VStack(spacing: 8) {
                        Text("Please enter your name and mobile number to complete your profile")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        if !userEmail.isEmpty {
                            Text("Email: \(userEmail)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Input Fields
                    VStack(spacing: 16) {
                        // Name Field
                        TextField("Enter your full name", text: $fullName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.name)
                            .autocapitalization(.words)
                            .disableAutocorrection(true)
                            .accessibilityLabel("Name input field")
                        
                        // Phone Field
                        TextField("Enter your mobile number", text: $mobileNumber)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .accessibilityLabel("Phone input field")
                    }
                    
                    // Continue Button
                    Button(action: handleContinue) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text("Continue")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(red: 0.298, green: 0.498, blue: 0.345))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(isLoading || fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || mobileNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("ContinueButton")
                    .accessibilityLabel("Continue with entered name and phone")
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func handleContinue() {
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = mobileNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validation
        guard !trimmedName.isEmpty else {
            showError("Please enter your name")
            return
        }
        
        guard trimmedName.count >= 2 else {
            showError("Name must be at least 2 characters long")
            return
        }
        
        guard !trimmedPhone.isEmpty else {
            showError("Please enter your mobile number")
            return
        }
        
        // Phone validation (10 digits)
        let phoneRegex = "^[0-9]{10}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        guard phonePredicate.evaluate(with: trimmedPhone) else {
            showError("Please enter a valid 10-digit mobile number")
            return
        }
        
        isLoading = true
        
        Task {
            await viewModel.completeProfile(name: trimmedName, phone: trimmedPhone)
            
            await MainActor.run {
                isLoading = false
                if viewModel.errorMessage == nil {
                    // Profile completed successfully, now set session in DataController
                    if let session = viewModel.lastSupabaseSession {
                        Task {
                            await dataController.setSessionFromApple(session: session)
                        }
                    }
                    dismiss()
                } else {
                    showError(viewModel.errorMessage ?? "Unknown error occurred")
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}

#Preview {
    ProfileCompletionView(userEmail: "test@example.com", viewModel: SignInWithAppleViewModel())
}
