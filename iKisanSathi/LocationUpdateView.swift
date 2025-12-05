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
    @State private var showingLocationPicker = false
    @State private var selectedLatitude: Double?
    @State private var selectedLongitude: Double?
    @State private var selectedAddress: String = ""
    
    private let ikisanGreen = Color(red: 0.298, green: 0.498, blue: 0.345)
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            if isLoading {
                LoadingView()
            } else {
                Form {
                    // Map Location Section
                    Section {
                        Button(action: {
                            showingLocationPicker = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "map.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(ikisanGreen)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Choose Location")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    if !selectedAddress.isEmpty {
                                        Text(selectedAddress)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    } else {
                                        Text("Tap to select on map")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } header: {
                        Text("Location")
                            .textCase(.uppercase)
                    }
                    
                    // Address Details Section
                    Section {
                        HStack {
                            Image(systemName: "building.2.fill")
                                .foregroundColor(ikisanGreen)
                                .frame(width: 24)
                            TextField("City", text: $city)
                        }
                        
                        HStack {
                            Image(systemName: "map.fill")
                                .foregroundColor(ikisanGreen)
                                .frame(width: 24)
                            TextField("State", text: $state)
                        }
                        
                        HStack {
                            Image(systemName: "number")
                                .foregroundColor(ikisanGreen)
                                .frame(width: 24)
                            TextField("Postal Code", text: $postalCode)
                                .keyboardType(.numberPad)
                        }
                        
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(ikisanGreen)
                                .frame(width: 24)
                            TextField("Country", text: $country)
                        }
                    } header: {
                        Text("Address Details")
                            .textCase(.uppercase)
                    } footer: {
                        Text("All fields are required to save your address.")
                            .font(.caption)
                    }
                    
                    // Save Button Section
                    Section {
                        Button(action: updateAddress) {
                            HStack {
                                Spacer()
                                Text("Save Address")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        .disabled(city.isEmpty || state.isEmpty || postalCode.isEmpty || country.isEmpty)
                        .foregroundColor(city.isEmpty || state.isEmpty || postalCode.isEmpty || country.isEmpty ? .secondary : .white)
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(city.isEmpty || state.isEmpty || postalCode.isEmpty || country.isEmpty ? Color(.systemGray5) : ikisanGreen)
                        )
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Update Address")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadExistingAddress()
        }
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
        .fullScreenCover(isPresented: $showingLocationPicker) {
            NavigationView {
                LocationPickerViewController_SwiftUI_Closure(
                    latitude: selectedLatitude ?? 28.4595, // Default to Greater Noida
                    longitude: selectedLongitude ?? 77.5026,
                    address: selectedAddress.isEmpty ? nil : selectedAddress,
                    purpose: .addressUpdate,
                    onLocationSelected: { latitude, longitude, address in
                        selectedLatitude = latitude
                        selectedLongitude = longitude
                        if let address = address {
                            selectedAddress = address
                            parseAddress(from: address)
                        }
                        showingLocationPicker = false
                    }
                )
                .navigationTitle("Select Location")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            showingLocationPicker = false
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            // Get the selected location from the location manager
                            let locationManager = LocationManager.shared
                            if let selectedLocation = locationManager.selectedLocation {
                                selectedLatitude = selectedLocation.latitude
                                selectedLongitude = selectedLocation.longitude
                                if let address = selectedLocation.address {
                                    selectedAddress = address
                                    parseAddress(from: address)
                                }
                            }
                            showingLocationPicker = false
                        }
                    }
                }
            }
        }
    }
    
    private func loadExistingAddress() {
        // Load existing address from current producer
        guard let currentProducer = dataController.currentProducer,
              let location = currentProducer.location,
              !location.isEmpty else {
            return
        }
        
        // Parse the existing location
        selectedAddress = location
        parseAddress(from: location)
    }
    
    private func parseAddress(from fullAddress: String) {
        // Split the address by commas
        let components = fullAddress.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        // Try to intelligently parse the address components
        // Typical format: "Street, City, State PostalCode, Country"
        if components.count >= 2 {
            // Extract country (usually last component)
            if let lastComponent = components.last, !lastComponent.isEmpty {
                country = lastComponent
            }
            
            // Extract city (usually first or second component)
            if components.count >= 2 {
                city = components[0]
            }
            
            // Extract state and postal code (usually second to last component)
            if components.count >= 3 {
                let statePostalComponent = components[components.count - 2]
                // Try to separate state and postal code
                let parts = statePostalComponent.components(separatedBy: " ")
                if parts.count >= 2 {
                    // Last part might be postal code
                    if let lastPart = parts.last, lastPart.rangeOfCharacter(from: .decimalDigits) != nil {
                        postalCode = lastPart
                        state = parts.dropLast().joined(separator: " ")
                    } else {
                        state = statePostalComponent
                    }
                } else {
                    state = statePostalComponent
                }
            }
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