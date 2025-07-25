import SwiftUI
import PhotosUI

struct AddEquipmentView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var name = ""
    @State private var type = ""
    @State private var capacity = ""
    @State private var availabilityStartDate = Date()
    @State private var availabilityEndDate = Date().addingTimeInterval(30*24*60*60) // 30 days ahead
    @State private var pricePerHour = ""
    @State private var realPricePerHour = ""
    @State private var pricePerAcre = ""
    @State private var realPricePerAcre = ""
    @State private var rating = 5.0
    @State private var location = ""
    @State private var selectedLatitude: Double?
    @State private var selectedLongitude: Double?
    @State private var coEquipDetail = coEquipState.Available
    @State private var modelYear = ""
    @State private var mielage = ""
    @State private var description = ""
    @State private var isRecommended = false
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingLocationPicker = false
    
    let equipmentTypes = ["Agricultural", "Rice", "Wheat"]
    
    var body: some View {
        NavigationView {
            Form {
                basicInformationSection
                availabilityLocationSection
                pricingSection
                equipmentDetailsSection
                statusSection
            }
            .navigationTitle("Add Equipment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEquipment()
                    }
                }
            }
            .alert("Equipment Status", isPresented: $showingAlert) {
                Button("OK") {
                    if alertMessage.contains("successfully") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .fullScreenCover(isPresented: $showingLocationPicker) {
                NavigationView {
                    LocationPickerViewController_SwiftUI_Closure(
                        latitude: selectedLatitude ?? 37.7749,
                        longitude: selectedLongitude ?? -122.4194,
                        address: location.isEmpty ? nil : location,
                        purpose: .equipmentLocation,
                        onLocationSelected: { latitude, longitude, address in
                            selectedLatitude = latitude
                            selectedLongitude = longitude
                            location = address ?? ""
                            showingLocationPicker = false
                        }
                    )
                    .navigationTitle("Select Equipment Location")
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
                                    location = selectedLocation.address ?? ""
                                }
                                showingLocationPicker = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Break down the complex form into separate computed properties
    private var basicInformationSection: some View {
        Section(header: Text("Basic Information")) {
            TextField("Equipment Name", text: $name)
            
            Picker("Equipment Type", selection: $type) {
                Text("Select Type").tag("")
                ForEach(equipmentTypes, id: \.self) { type in
                    Text(type).tag(type)
                }
            }
            
            imagePickerView
            
            TextField("Capacity", text: $capacity)
        }
    }
    
    private var imagePickerView: some View {
        VStack {
            if let selectedImageData,
               let uiImage = UIImage(data: selectedImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(8)
            }
            
            PhotosPicker(selection: $selectedItem,
                       matching: .images,
                       photoLibrary: .shared()) {
                HStack {
                    Image(systemName: "photo")
                    Text(selectedImageData == nil ? "Select Equipment Photo" : "Change Photo")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    selectedImageData = data
                }
            }
        }
    }
    
    private var availabilityLocationSection: some View {
        Section(header: Text("Availability & Location")) {
            DatePicker("Start Date", selection: $availabilityStartDate, displayedComponents: [.date])
            DatePicker("End Date", selection: $availabilityEndDate, displayedComponents: [.date])
            
            locationPickerButton
        }
    }
    
    private var locationPickerButton: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Location")
                    .foregroundColor(.primary)
                Spacer()
            }
            
            Button(action: {
                showingLocationPicker = true
            }) {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.blue)
                    
                    if location.isEmpty {
                        Text("Select Equipment Location")
                            .foregroundColor(.secondary)
                    } else {
                        Text(location)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var pricingSection: some View {
        Section(header: Text("Pricing")) {
            TextField("Price per Hour ($)", text: $pricePerHour)
                .keyboardType(.decimalPad)
            TextField("Real Price per Hour ($)", text: $realPricePerHour)
                .keyboardType(.decimalPad)
            TextField("Price per Acre ($)", text: $pricePerAcre)
                .keyboardType(.decimalPad)
            TextField("Real Price per Acre ($)", text: $realPricePerAcre)
                .keyboardType(.decimalPad)
        }
    }
    
    private var equipmentDetailsSection: some View {
        Section(header: Text("Equipment Details")) {
            TextField("Model Year", text: $modelYear)
                .keyboardType(.numberPad)
            TextField("Mileage", text: $mielage)
            TextField("Description", text: $description, axis: .vertical)
                .lineLimit(3...6)
        }
    }
    
    private var statusSection: some View {
        Section(header: Text("Status")) {
            Picker("Equipment Status", selection: $coEquipDetail) {
                Text("Available").tag(coEquipState.Available)
                Text("Unavailable").tag(coEquipState.Unavailable)
            }
            Toggle("Recommended Equipment", isOn: $isRecommended)
        }
    }
    
    private func saveEquipment() {
        // Basic Information Validation
        guard !name.isEmpty else {
            alertMessage = "Please enter equipment name"
            showingAlert = true
            return
        }
        
        guard !type.isEmpty else {
            alertMessage = "Please select equipment type"
            showingAlert = true
            return
        }
        
        guard selectedImageData != nil else {
            alertMessage = "Please select an equipment photo"
            showingAlert = true
            return
        }
        
        guard !capacity.isEmpty else {
            alertMessage = "Please specify equipment capacity"
            showingAlert = true
            return
        }
        
        // Date Validation
        guard availabilityStartDate <= availabilityEndDate else {
            alertMessage = "End date must be after start date"
            showingAlert = true
            return
        }
        
        // Price Validation
        guard let priceHour = Double(pricePerHour), priceHour > 0,
              let realPriceHour = Double(realPricePerHour), realPriceHour > 0,
              let priceAcre = Double(pricePerAcre), priceAcre > 0,
              let realPriceAcre = Double(realPricePerAcre), realPriceAcre > 0 else {
            alertMessage = "Please enter valid prices"
            showingAlert = true
            return
        }
        
        // Location Validation
        guard !location.isEmpty else {
            alertMessage = "Please specify equipment location"
            showingAlert = true
            return
        }
        
        // Equipment Details Validation
        guard !modelYear.isEmpty else {
            alertMessage = "Please specify model year"
            showingAlert = true
            return
        }
        
        guard !mielage.isEmpty else {
            alertMessage = "Please specify mileage"
            showingAlert = true
            return
        }
        
        // Save to Supabase
        Task {
            do {
                guard let currentUser = dataController.currentUser else {
                    alertMessage = "User not logged in"
                    showingAlert = true
                    return
                }
                
                // Upload image to Supabase storage and get URL
                guard let imageData = selectedImageData else {
                    alertMessage = "Failed to process image"
                    showingAlert = true
                    return
                }
                
                let imageUrl = try await dataController.uploadEquipmentImage(imageData)
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                
                let equipment = DataController.Equipment(
                    equipmentID: UUID(),
                    equipmentImage: imageUrl,
                    name: name,
                    type: type,
                    capacity: capacity,
                    availabilityStartDate: dateFormatter.string(from: availabilityStartDate),
                    availabilityEndDate: dateFormatter.string(from: availabilityEndDate),
                    pricePerHour: Double(pricePerHour) ?? 0.0,
                    realPricePerHour: Double(realPricePerHour) ?? 0.0,
                    pricePerAcre: Double(pricePerAcre) ?? 0.0,
                    realPricePerAcre: Double(realPricePerAcre) ?? 0.0,
                    providerID: currentUser.id,
                    rating: rating,
                    location: location,
                    coEquipDetail: coEquipDetail,
                    modelYear: modelYear,
                    mielage: mielage,
                    description: description,
                    isRecommended: isRecommended,
                    providerName: dataController.currentProducer?.name ?? currentUser.email,
                    preBookingStatus: nil)
                
                try await dataController.addEquipment(equipment)
                
                alertMessage = "Equipment added successfully"
                showingAlert = true
                dismiss()
            } catch {
                alertMessage = "Error adding equipment: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
}
