import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    @State private var userProfile: DataController.UserProfile?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        ZStack {
            Color(.systemGray6).edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header with Image
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .center) {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .foregroundColor(.green)
                                .background(Circle().fill(Color.white))
                                .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                            
                            Text(userProfile?.name ?? dataController.currentProducer?.name ?? "John Smith")
                                .font(.title)
                                .fontWeight(.bold)
                                .padding(.top, 8)
                            
                            Text(userProfile?.email ?? dataController.currentUser?.email ?? "john.smith@email.com")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(userProfile?.phone ?? dataController.currentProducer?.phone ?? "+1 (555) 123-4567")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.top, 2)
                            
                            Text(userProfile?.address ?? dataController.currentProducer?.location ?? "123 Farmland Road, Agricultural Valley, AV 12345")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.top, 2)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Account Details Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Account Details")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.bottom, 4)
                        
                        // Rating
                        HStack {
                            HStack(spacing: 2) {
                                ForEach(0..<4, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.green)
                                }
                                Image(systemName: "star.leadinghalf.filled")
                                    .foregroundColor(.green)
                            }
                            Text("4.8/5.0")
                                .foregroundColor(.secondary)
                                .padding(.leading, 4)
                        }
                        
                        // Account Number
                        HStack {
                            Text("Account Number:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(userProfile?.phone ?? dataController.currentProducer?.phone ?? "+1 (555) 123-4567")
                        }
                        
                        // IFSC Code
                        HStack {
                            Text("IFSC Code:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("IKIS00012345")
                        }
                        
                        // Field Area
                        if let fieldArea = userProfile?.fieldArea {
                            HStack {
                                Text("Field Area:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(String(format: "%.2f", fieldArea)) acres")
                            }
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
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
}
