//
//  LocationUpdateView.swift
//  iKisanSathi
//
//  Created by harsh chauhan
//

import SwiftUI
import MapKit

struct LocationUpdateView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    @State private var city = ""
    @State private var state = ""
    @State private var postalCode = ""
    @State private var country = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showingError = false
    @State private var showingSuccess = false
    
    private let ikisanGreen = Color(red: 0.298, green: 0.498, blue: 0.345)
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            if isLoading {
                LoadingView()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // Map Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("LOCATION ON MAP")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                
                                VStack {
                                    // Map Preview
                                    ZStack {
                                        Color(.systemGray5)
                                            .frame(height: 200)
                                        
                                        // Map placeholder with streets
                                        Image(systemName: "map")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 100, height: 100)
                                            .foregroundColor(.gray.opacity(0.7))
                                            .overlay(
                                                Image(systemName: "mappin.circle.fill")
                                                    .resizable()
                                                    .frame(width: 30, height: 30)
                                                    .foregroundColor(.red)
                                                    .offset(y: -10)
                                            )
                                    }
                                    
                                    // Choose Location Button
                                    Button(action: {
                                        // Action to open map picker
                                    }) {
                                        HStack {
                                            Image(systemName: "map")
                                                .foregroundColor(ikisanGreen)
                                            Text("Choose Location on Map")
                                                .foregroundColor(ikisanGreen)
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(ikisanGreen, lineWidth: 1)
                                        )
                                    }
                                    .padding(.horizontal)
                                    .padding(.bottom)
                                }
                            }
                            .padding(.bottom)
                        }
                        
                        // Address Details Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ADDRESS DETAILS")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                // City
                                TextField("Greater Noida", text: $city)
                                    .padding()
                                    .background(Color.white)
                                
                                Divider()
                                
                                // State
                                TextField("Uttar Pradesh", text: $state)
                                    .padding()
                                    .background(Color.white)
                                
                                Divider()
                                
                                // Postal Code
                                TextField("201310", text: $postalCode)
                                    .padding()
                                    .background(Color.white)
                                    .keyboardType(.numberPad)
                                
                                Divider()
                                
                                // Country
                                TextField("India", text: $country)
                                    .padding()
                                    .background(Color.white)
                            }
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        }
                        
                        // Use Current Location Button
                        Button(action: {
                            // This would typically use CoreLocation to get the user's current location
                            // For this example, we'll just set placeholder values
                            city = "Greater Noida"
                            state = "Uttar Pradesh"
                            postalCode = "201310"
                            country = "India"
                        }) {
                            HStack {
                                Image(systemName: "location.fill")
                                Text("Use Current Location")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(ikisanGreen)
                            .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        
                        // Save Address Button
                        Button(action: updateAddress) {
                            Text("Save Address")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(ikisanGreen)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        .disabled(city.isEmpty || state.isEmpty || postalCode.isEmpty || country.isEmpty)
                        .opacity(city.isEmpty || state.isEmpty || postalCode.isEmpty || country.isEmpty ? 0.6 : 1)
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("Update Address")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .alert("Success", isPresented: $showingSuccess) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Your address has been updated successfully.")
        }
    }
    
    private func updateAddress() {
        guard !city.isEmpty && !state.isEmpty && !postalCode.isEmpty && !country.isEmpty else { return }
        guard let currentUser = dataController.currentUser else {
            errorMessage = "User not logged in"
            showingError = true
            return
        }
        
        isLoading = true
        
        // Combine address components
        let fullAddress = "\(city), \(state), \(postalCode), \(country)"
        
        Task {
            do {
                // Update the producer record in the database
                let database = dataController.getDatabase()
                
                try await database
                    .from("producer")
                    .update(["location": fullAddress])
                    .eq("id", value: currentUser.id.uuidString)
                    .execute()
                
                // Update the local currentProducer
                await MainActor.run {
                    if var updatedProducer = dataController.currentProducer {
                        updatedProducer.location = fullAddress
                        dataController.currentProducer = updatedProducer
                    }
                    
                    isLoading = false
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to update address: \(error.localizedDescription)"
                    showingError = true
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        LocationUpdateView()
            .environmentObject(DataController())
    }
}