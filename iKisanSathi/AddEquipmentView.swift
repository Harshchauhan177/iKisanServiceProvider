import SwiftUI
import PhotosUI

struct AddEquipmentView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImagesData: [Data] = []
    @State private var name = ""
    @State private var type = ""
    @State private var capacity = ""
    @State private var availabilityStartDate = Date()
    @State private var availabilityEndDate = Date().addingTimeInterval(30*24*60*60) // 30 days ahead
    @State private var pricePerHour: Double = 0.0
    @State private var realPricePerHour: Double = 0.0
    @State private var pricePerAcre: Double = 0.0
    @State private var realPricePerAcre: Double = 0.0
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
    @State private var isSaving = false
    
    // Validation states
    @State private var nameError: String? = nil
    @State private var capacityError: String? = nil
    @State private var pricePerHourError: String? = nil
    @State private var realPricePerHourError: String? = nil
    @State private var pricePerAcreError: String? = nil
    @State private var realPricePerAcreError: String? = nil
    @State private var modelYearError: String? = nil
    @State private var mileageError: String? = nil
    
    let equipmentTypes = ["Agricultural", "Rice", "Wheat"]
    
    // Input constraints
    private let maxNameLength = 50
    private let maxCapacityLength = 30
    private let maxDescriptionLength = 500
    private let maxMileageLength = 10
    private let currentYear = Calendar.current.component(.year, from: Date())
    private let minYear = 1980
    
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
                    .disabled(isSaving)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEquipment()
                    }
                    .disabled(isSaving)
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
            VStack(alignment: .leading) {
                TextField("Equipment Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: name) { newValue in
                        validateName(newValue)
                    }
                if let error = nameError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 2)
                }
            }
            
            Picker("Equipment Type", selection: $type) {
                Text("Select Type").tag("")
                ForEach(equipmentTypes, id: \.self) { type in
                    Text(type).tag(type)
                }
            }
            .pickerStyle(MenuPickerStyle())
            
            imagePickerView
            
            VStack(alignment: .leading) {
                TextField("Capacity (e.g., 100 HP, 5 tons)", text: $capacity)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: capacity) { newValue in
                        validateCapacity(newValue)
                    }
                if let error = capacityError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 2)
                }
            }
        }
    }
    
    private var imagePickerView: some View {
        VStack {
            if !selectedImagesData.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(selectedImagesData, id: \.self) { imageData in
                            if let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .cornerRadius(8)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                }
            }
            
            PhotosPicker(selection: $selectedItems,
                       matching: .images,
                       photoLibrary: .shared()) {
                HStack {
                    Image(systemName: "photo")
                    Text(selectedImagesData.isEmpty ? "Select Equipment Photos" : "Add More Photos")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .onChange(of: selectedItems) { newItems in
                Task {
                    // Don't clear existing images, process only new ones
                    for newItem in newItems {
                        if let data = try? await newItem.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            // Maximum allowed file size (500KB)
                            let maxFileSize: Int = 500 * 1024
                            
                            // Compress with reducing dimensions first
                            let maxDimension: CGFloat = 800
                            let scale = min(maxDimension / uiImage.size.width, maxDimension / uiImage.size.height, 1.0)
                            let newSize = CGSize(width: uiImage.size.width * scale, height: uiImage.size.height * scale)
                            
                            let renderer = UIGraphicsImageRenderer(size: newSize)
                            let resizedImage = renderer.image { context in
                                uiImage.draw(in: CGRect(origin: .zero, size: newSize))
                            }
                            
                            // Start with high quality and progressively reduce until file size is acceptable
                            var compressionQuality: CGFloat = 0.8
                            var imageData = resizedImage.jpegData(compressionQuality: compressionQuality)
                            
                            while let data = imageData, data.count > maxFileSize && compressionQuality > 0.1 {
                                compressionQuality -= 0.1
                                imageData = resizedImage.jpegData(compressionQuality: compressionQuality)
                            }
                            
                            if let finalImageData = imageData {
                                await MainActor.run {
                                    selectedImagesData.append(finalImageData)
                                }
                            }
                        }
                    }
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
            VStack(alignment: .leading) {
                HStack {
                    Text("₨")
                        .foregroundColor(.secondary)
                        .font(.headline)
                    TextField("Price per Hour", value: $pricePerHour, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .onChange(of: pricePerHour) { newValue in
                    validatePricePerHour(newValue)
                }
                if let error = pricePerHourError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 2)
                } else {
                    Text("Minimum: ₨10, Maximum: ₨10,000")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading) {
                HStack {
                    Text("₨")
                        .foregroundColor(.secondary)
                        .font(.headline)
                    TextField("Real Price per Hour", value: $realPricePerHour, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .onChange(of: realPricePerHour) { newValue in
                    validateRealPricePerHour(newValue)
                }
                if let error = realPricePerHourError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 2)
                } else {
                    Text("Minimum: ₨10, Maximum: ₨10,000")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading) {
                HStack {
                    Text("₨")
                        .foregroundColor(.secondary)
                        .font(.headline)
                    TextField("Price per Acre", value: $pricePerAcre, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .onChange(of: pricePerAcre) { newValue in
                    validatePricePerAcre(newValue)
                }
                if let error = pricePerAcreError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 2)
                } else {
                    Text("Minimum: ₨100, Maximum: ₨50,000")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading) {
                HStack {
                    Text("₨")
                        .foregroundColor(.secondary)
                        .font(.headline)
                    TextField("Real Price per Acre", value: $realPricePerAcre, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .onChange(of: realPricePerAcre) { newValue in
                    validateRealPricePerAcre(newValue)
                }
                if let error = realPricePerAcreError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 2)
                } else {
                    Text("Minimum: ₨100, Maximum: ₨50,000")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var equipmentDetailsSection: some View {
        Section(header: Text("Equipment Details")) {
            TextField("Model Year", text: $modelYear)
                .keyboardType(.numberPad)
                .onChange(of: modelYear) { newValue in
                    // Validate model year as a number within the valid range
                    if let value = Int(newValue), value < minYear || value > currentYear {
                        modelYear = ""
                    }
                }
            TextField("Mileage", text: $mielage)
                .onChange(of: mielage) { newValue in
                    // Validate mileage length
                    if newValue.count > maxMileageLength {
                        mielage = String(newValue.prefix(maxMileageLength))
                    }
                }
            TextField("Description", text: $description, axis: .vertical)
                .lineLimit(3...6)
                .onChange(of: description) { newValue in
                    // Validate description length
                    if newValue.count > maxDescriptionLength {
                        description = String(newValue.prefix(maxDescriptionLength))
                    }
                }
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
        
        guard !selectedImagesData.isEmpty else {
            alertMessage = "Please select at least one equipment photo"
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
        guard pricePerHour > 0,
              realPricePerHour > 0,
              pricePerAcre > 0,
              realPricePerAcre > 0 else {
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
        
        isSaving = true // Start saving
        
        // Save to Supabase
        Task {
            do {
                guard let currentUser = dataController.currentUser else {
                    alertMessage = "User not logged in"
                    showingAlert = true
                    isSaving = false
                    return
                }
                
                // Upload images to Supabase storage and get URLs
                let imageUrls = try await dataController.uploadMultipleEquipmentImages(selectedImagesData)
                
                guard !imageUrls.isEmpty else {
                    alertMessage = "Failed to upload images"
                    showingAlert = true
                    isSaving = false
                    return
                }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                
                let equipmentID = UUID()
                
                let equipment = DataController.Equipment(
                    equipmentID: equipmentID,
                    equipmentImage: imageUrls.first!, // Use first image as main image
                    name: name,
                    type: type,
                    capacity: capacity,
                    availabilityStartDate: dateFormatter.string(from: availabilityStartDate),
                    availabilityEndDate: dateFormatter.string(from: availabilityEndDate),
                    pricePerHour: pricePerHour,
                    realPricePerHour: realPricePerHour,
                    pricePerAcre: pricePerAcre,
                    realPricePerAcre: realPricePerAcre,
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
                
                // Save additional images to equipmentMoreImages table if there are more than 1 image
                if imageUrls.count > 1 {
                    let additionalImages = Array(imageUrls.dropFirst()) // Skip the first image
                    try await dataController.saveEquipmentMoreImages(equipmentID: equipmentID, imageUrls: additionalImages)
                }
                
                alertMessage = "Equipment added successfully"
                showingAlert = true
                dismiss()
            } catch {
                alertMessage = "Error adding equipment: \(error.localizedDescription)"
                showingAlert = true
            }
            isSaving = false // End saving
        }
    }
    
    private func validateName(_ name: String) {
        // Name must not be empty and should have a maximum length
        if name.isEmpty {
            nameError = "Equipment name is required"
        } else if name.count > maxNameLength {
            nameError = "Name must be less than \(maxNameLength) characters"
        } else {
            nameError = nil
        }
    }
    
    private func validateCapacity(_ capacity: String) {
        // Capacity must not be empty and should have a maximum length
        if capacity.isEmpty {
            capacityError = "Capacity is required"
        } else if capacity.count > maxCapacityLength {
            capacityError = "Capacity must be less than \(maxCapacityLength) characters"
        } else {
            capacityError = nil
        }
    }
    
    private func validatePricePerHour(_ price: Double) {
        // Price per hour must be between 10 and 10,000
        if price < 10 {
            pricePerHourError = "Price per hour must be at least ₨10"
        } else if price > 10000 {
            pricePerHourError = "Price per hour must not exceed ₨10,000"
        } else {
            pricePerHourError = nil
        }
    }
    
    private func validateRealPricePerHour(_ price: Double) {
        // Real price per hour must be between 10 and 10,000
        if price < 10 {
            realPricePerHourError = "Real price per hour must be at least ₨10"
        } else if price > 10000 {
            realPricePerHourError = "Real price per hour must not exceed ₨10,000"
        } else {
            realPricePerHourError = nil
        }
    }
    
    private func validatePricePerAcre(_ price: Double) {
        // Price per acre must be between 100 and 50,000
        if price < 100 {
            pricePerAcreError = "Price per acre must be at least ₨100"
        } else if price > 50000 {
            pricePerAcreError = "Price per acre must not exceed ₨50,000"
        } else {
            pricePerAcreError = nil
        }
    }
    
    private func validateRealPricePerAcre(_ price: Double) {
        // Real price per acre must be between 100 and 50,000
        if price < 100 {
            realPricePerAcreError = "Real price per acre must be at least ₨100"
        } else if price > 50000 {
            realPricePerAcreError = "Real price per acre must not exceed ₨50,000"
        } else {
            realPricePerAcreError = nil
        }
    }
}

struct AddEquipmentView_Previews: PreviewProvider {
    static var previews: some View {
        AddEquipmentView()
            .environmentObject(DataController())
    }
}
