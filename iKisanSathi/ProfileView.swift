//
//  SignInWithAppleViewModel.swift
//  iKisanSathi
//
//  Created by harsh chauhan on 03/06/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    @State private var userProfile: DataController.UserProfile?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var isEditMode = false
    
    // Editable fields
    @State private var name = ""
    @State private var phone = ""
    @State private var location = ""
    @State private var accountNo = ""
    @State private var ifcsCode = ""
    
    var body: some View {
        ZStack {
            Color(.systemGray6).edgesIgnoringSafeArea(.all)
            
            if isLoading {
                LoadingView()
            }
            
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header with Image
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .center) {
                            Group {
                                if let profileImageUrl = userProfile?.profileimage ?? dataController.currentProducer?.profileimage,
                                   !profileImageUrl.isEmpty,
                                   let url = URL(string: profileImageUrl) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(width: 100, height: 100)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 100, height: 100)
                                                .clipShape(Circle())
                                                .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                                        case .failure:
                                            Image(systemName: "person.circle.fill")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 100, height: 100)
                                                .foregroundColor(.green)
                                                .background(Circle().fill(Color.white))
                                                .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                                        @unknown default:
                                            Image(systemName: "person.circle.fill")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 100, height: 100)
                                                .foregroundColor(.green)
                                                .background(Circle().fill(Color.white))
                                                .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                                        }
                                    }
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.green)
                                        .background(Circle().fill(Color.white))
                                        .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                                }
                            }
                            
                            if isEditMode {
                                TextField("Name", text: $name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 8)
                            } else {
                                Text(userProfile?.name ?? dataController.currentProducer?.name ?? "John Smith")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .padding(.top, 8)
                            }
                            
                            Text(userProfile?.email ?? dataController.currentUser?.email ?? "john.smith@email.com")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if isEditMode {
                                TextField("Phone", text: $phone)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 2)
                            } else {
                                Text(userProfile?.phone ?? dataController.currentProducer?.phone ?? "+1 (555) 123-4567")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 2)
                            }
                            
                            if isEditMode {
                                TextField("Location", text: $location)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 2)
                                    .padding(.horizontal)
                            } else {
                                Text(userProfile?.location ?? dataController.currentProducer?.location ?? "123 Farmland Road, Agricultural Valley, AV 12345")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 2)
                                    .padding(.horizontal)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Account Details Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Account Details")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    VStack(alignment: .leading, spacing: 16) {
//                        Text("Account Details")
//                            .font(.title2)
//                            .fontWeight(.bold)
//                            .padding(.bottom, 4)
                        
                        // Rating
//                        HStack {
//                            HStack(spacing: 2) {
//                                ForEach(0..<4, id: \.self) { _ in
//                                    Image(systemName: "star.fill")
//                                        .foregroundColor(.green)
//                                }
//                                Image(systemName: "star.leadinghalf.filled")
//                                    .foregroundColor(.green)
//                            }
//                            Text("4.8/5.0")
//                                .foregroundColor(.secondary)
//                                .padding(.leading, 4)
//                        }
                        
                        // Account Number
                        HStack {
                            Text("Account Number:")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                            if isEditMode {
                                TextField("Account Number", text: $accountNo)
                                    .multilineTextAlignment(.trailing)
                            } else {
                                Text(userProfile?.accountNo ?? dataController.currentProducer?.accountNo ?? "Not provided")
                            }
                        }
                        
                        // IFSC Code
                        HStack {
                            Text("IFSC Code:")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                            if isEditMode {
                                TextField("IFSC Code", text: $ifcsCode)
                                    .multilineTextAlignment(.trailing)
                            } else {
                                Text(userProfile?.ifcsCode ?? dataController.currentProducer?.ifcsCode ?? "Not provided")
                            }
                        }
                        
                        // Rating
//                        HStack {
//                            Text("Rating:")
//                                .foregroundColor(.secondary)
//                            Spacer()
//                            if let rating = userProfile?.rating ?? dataController.currentProducer?.rating {
//                                HStack(spacing: 2) {
//                                    ForEach(0..<Int(rating), id: \.self) { _ in
//                                        Image(systemName: "star.fill")
//                                            .foregroundColor(.green)
//                                    }
//                                    if rating - Double(Int(rating)) >= 0.5 {
//                                        Image(systemName: "star.leadinghalf.filled")
//                                            .foregroundColor(.green)
//                                    }
//                                }
//                                Text("\(String(format: "%.1f", rating))/5.0")
//                                    .foregroundColor(.secondary)
//                                    .padding(.leading, 4)
//                            } else {
//                                Text("Not rated yet")
//                            }
//                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    }

                    
                    // Actions Section
                     VStack(alignment: .leading, spacing: 0) {
                        Text("ACTIONS")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.bottom, 8)

                        VStack(spacing: 0) {
                            // Help Center Card
                            NavigationLink(destination: HelpCenterView()) {
                                HStack {
                                    Image(systemName: "questionmark.circle.fill")
                                        .foregroundColor(.green)
                                        .frame(width: 30, height: 30)
                                        .background(Color(.systemGray6))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    Text("Help Center")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                            }
                            
                            Divider()
                                .padding(.horizontal)
                            
                            // Update Address Card
                            NavigationLink(destination: LocationUpdateView()) {
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(.green)
                                        .frame(width: 30, height: 30)
                                        .background(Color(.systemGray6))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    Text("Update Address")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                            }
                        }
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                     }
                    // Legal Section with both cards
                    VStack(alignment: .leading, spacing: 0) {
                        Text("LEGAL")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 0) {
                            // Terms & Privacy Policy Card
                            NavigationLink(destination: TermsPrivacyView()) {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                        .foregroundColor(.green)
                                        .frame(width: 30, height: 30)
                                        .background(Color(.systemGray6))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    Text("Terms & Privacy Policy")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                            }
                            
                            Divider()
                                .padding(.horizontal)
                            
                            // App Info Card
                            NavigationLink(destination: AppInfoView()) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.green)
                                        .frame(width: 30, height: 30)
                                        .background(Color(.systemGray6))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    Text("App Info")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                            }
                        }
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                    
                    
                    // Sign Out Button
                    Button {
                        Task {
                            try? await dataController.signOut()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Sign Out")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditMode ? "Save" : "Edit") {
                    if isEditMode {
                        // Save changes
                        saveChanges()
                    } else {
                        // Enter edit mode
                        enterEditMode()
                    }
                    isEditMode.toggle()
                }
                .foregroundColor(.blue)
            }
        }
        .onAppear {
            fetchUserProfile()
        }
        .alert("Error", isPresented: $showingError, actions: {
            Button("OK", role: .cancel) {}
        }, message: {
            Text(errorMessage ?? "An error occurred")
        })
    }
    
    private func fetchUserProfile() {
        guard let currentUser = dataController.currentUser else { return }
        
        isLoading = true
        
        Task {
            do {
                let profiles = try await dataController.fetchUserProfile(email: currentUser.email)
                
                await MainActor.run {
                    if let profile = profiles.first {
                        self.userProfile = profile
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load profile: \(error.localizedDescription)"
                    showingError = true
                    isLoading = false
                }
            }
        }
    }
    
    private func enterEditMode() {
        // Initialize editable fields with current values
        name = userProfile?.name ?? dataController.currentProducer?.name ?? ""
        phone = userProfile?.phone ?? dataController.currentProducer?.phone ?? ""
        location = userProfile?.location ?? dataController.currentProducer?.location ?? ""
        accountNo = userProfile?.accountNo ?? dataController.currentProducer?.accountNo ?? ""
        ifcsCode = userProfile?.ifcsCode ?? dataController.currentProducer?.ifcsCode ?? ""
    }
    
    private func saveChanges() {
        isLoading = true
        
        guard let currentProfile = userProfile else {
            errorMessage = "Could not update profile: Profile data not available"
            showingError = true
            isLoading = false
            return
        }
        
        Task {
            do {
                // Update the profile in the database
                try await updateUserProfile(userID: currentProfile.userID.uuidString)
                
                await MainActor.run {
                    // Refresh the profile
                    fetchUserProfile()
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to update profile: \(error.localizedDescription)"
                    showingError = true
                    isLoading = false
                }
            }
        }
    }
    
    private func updateUserProfile(userID: String) async throws {
        // Create a struct that conforms to Encodable for the update
        struct ProfileUpdate: Encodable {
            let name: String
            let phone: String
            let location: String
            let accountNo: String
            let ifcsCode: String
        }
        
        let updateData = ProfileUpdate(
            name: name,
            phone: phone,
            location: location,
            accountNo: accountNo,
            ifcsCode: ifcsCode
        )
        
        // Get access to the database through the dataController
        let database = dataController.getDatabase()
        
        // Update the producer record in the database
        try await database
            .from("producer")
            .update(updateData)
            .eq("id", value: userID)
            .execute()
        
        // Update the local currentProducer
        await MainActor.run {
            if var updatedProducer = dataController.currentProducer {
                updatedProducer.name = name
                updatedProducer.phone = phone
                updatedProducer.location = location
                updatedProducer.accountNo = accountNo
                updatedProducer.ifcsCode = ifcsCode
                
                dataController.currentProducer = updatedProducer
            }
        }
    }
    

}
