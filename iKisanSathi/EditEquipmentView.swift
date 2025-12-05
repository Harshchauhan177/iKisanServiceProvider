import SwiftUI
import PhotosUI

struct EditEquipmentView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    let equipment: DataController.Equipment
    var isPresentedModally: Bool = false  // Default to false for push navigation
    
    @State private var name: String
    @State private var type: String
    @State private var capacity: String
    @State private var pricePerHour: Double
    @State private var pricePerAcre: Double
    @State private var realPricePerHour: Double
    @State private var realPricePerAcre: Double
    @State private var isDiscountEnabled: Bool
    @State private var location: String
    @State private var selectedLatitude: Double?
    @State private var selectedLongitude: Double?
    @State private var modelYear: String
    @State private var mileage: String
    @State private var description: String
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var showingDeleteAlert = false
    @State private var showingLocationPicker = false
    @State private var isSaving = false
    @State private var hasChanges = false
    
    // Image management - support multiple images
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var existingImageURLs: [String] = []
    @State private var newImagesData: [Data] = []
    @State private var hasImageChanged = false
    @State private var isLoadingImages = true
    @State private var originalImageURLs: [String] = [] // Track original images for deletion
    
    // Validation states
    @State private var nameError: String? = nil
    @State private var capacityError: String? = nil
    @State private var pricePerHourError: String? = nil
    @State private var pricePerAcreError: String? = nil
    @State private var realPricePerHourError: String? = nil
    @State private var realPricePerAcreError: String? = nil
    @State private var modelYearError: String? = nil
    @State private var mileageError: String? = nil
    
    // Input constraints
    private let maxNameLength = 50
    private let maxCapacityLength = 30
    private let maxDescriptionLength = 500
    private let maxMileageLength = 10
    private let currentYear = Calendar.current.component(.year, from: Date())
    private let minYear = 1980
    
    let equipmentTypes = ["Agricultural", "Rice", "Wheat"]
    
    init(equipment: DataController.Equipment, isPresentedModally: Bool = false) {
        self.equipment = equipment
        self.isPresentedModally = isPresentedModally
        _name = State(initialValue: equipment.name)
        _type = State(initialValue: equipment.type)
        _capacity = State(initialValue: equipment.capacity)
        _pricePerHour = State(initialValue: equipment.pricePerHour)
        _pricePerAcre = State(initialValue: equipment.pricePerAcre)
        _realPricePerHour = State(initialValue: equipment.realPricePerHour)
        _realPricePerAcre = State(initialValue: equipment.realPricePerAcre)
        // Check if discount is enabled (real price differs from display price)
        _isDiscountEnabled = State(initialValue: equipment.pricePerHour != equipment.realPricePerHour || equipment.pricePerAcre != equipment.realPricePerAcre)
        _location = State(initialValue: equipment.location)
        _modelYear = State(initialValue: equipment.modelYear)
        _mileage = State(initialValue: equipment.mielage)
        _description = State(initialValue: equipment.description ?? "")
        // Initialize with existing image if available
        _existingImageURLs = State(initialValue: equipment.equipmentImage.isEmpty ? [] : [equipment.equipmentImage])
    }
    
    var body: some View {
        Form {
                Section(header: Text("Basic Information")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Equipment Name")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        TextField("Enter equipment name", text: $name)
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
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Equipment Type")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Picker("Select Type", selection: $type) {
                            ForEach(equipmentTypes, id: \.self) { equipmentType in
                                Text(equipmentType).tag(equipmentType)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    // Equipment Images - Multiple photos support
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Equipment Photos")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        // Show loading indicator while fetching images
                        if isLoadingImages {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                        }
                        // Display existing and new images in horizontal scroll
                        else if !existingImageURLs.isEmpty || !newImagesData.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    // Show existing images from server
                                    ForEach(Array(existingImageURLs.enumerated()), id: \.offset) { index, imageURL in
                                        ZStack(alignment: .topTrailing) {
                                            AsyncImage(url: URL(string: imageURL)) { phase in
                                                switch phase {
                                                case .empty:
                                                    ProgressView()
                                                        .frame(width: 120, height: 120)
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 120, height: 120)
                                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                                case .failure:
                                                    Image(systemName: "photo.fill")
                                                        .font(.system(size: 40))
                                                        .foregroundColor(.gray)
                                                        .frame(width: 120, height: 120)
                                                        .background(Color(.systemGray6))
                                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                                @unknown default:
                                                    EmptyView()
                                                }
                                            }
                                            
                                            // Remove button
                                            Button(action: {
                                                existingImageURLs.remove(at: index)
                                                hasImageChanged = true
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(.white)
                                                    .background(Circle().fill(Color.red))
                                            }
                                            .offset(x: 8, y: -8)
                                        }
                                    }
                                    
                                    // Show newly selected images (not yet uploaded)
                                    ForEach(Array(newImagesData.enumerated()), id: \.offset) { index, imageData in
                                        ZStack(alignment: .topTrailing) {
                                            if let uiImage = UIImage(data: imageData) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 120, height: 120)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(Color.blue, lineWidth: 2)
                                                    )
                                            }
                                            
                                            // Remove button
                                            Button(action: {
                                                newImagesData.remove(at: index)
                                                hasImageChanged = true
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(.white)
                                                    .background(Circle().fill(Color.red))
                                            }
                                            .offset(x: 8, y: -8)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        
                        // Add photos button
                        PhotosPicker(selection: $selectedItems,
                                   matching: .images,
                                   photoLibrary: .shared()) {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                Text(existingImageURLs.isEmpty && newImagesData.isEmpty ? "Select Equipment Photos" : "Add More Photos")
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .onChange(of: selectedItems) { newItems in
                            Task {
                                // Process all new items
                                for newItem in newItems {
                                    if let data = try? await newItem.loadTransferable(type: Data.self),
                                       let uiImage = UIImage(data: data) {
                                        // Compress image
                                        let maxFileSize: Int = 500 * 1024
                                        let maxDimension: CGFloat = 800
                                        let scale = min(maxDimension / uiImage.size.width, maxDimension / uiImage.size.height, 1.0)
                                        let newSize = CGSize(width: uiImage.size.width * scale, height: uiImage.size.height * scale)
                                        
                                        let renderer = UIGraphicsImageRenderer(size: newSize)
                                        let resizedImage = renderer.image { context in
                                            uiImage.draw(in: CGRect(origin: .zero, size: newSize))
                                        }
                                        
                                        var compressionQuality: CGFloat = 0.8
                                        var imageData = resizedImage.jpegData(compressionQuality: compressionQuality)
                                        
                                        while let data = imageData, data.count > maxFileSize && compressionQuality > 0.1 {
                                            compressionQuality -= 0.1
                                            imageData = resizedImage.jpegData(compressionQuality: compressionQuality)
                                        }
                                        
                                        if let finalImageData = imageData {
                                            await MainActor.run {
                                                newImagesData.append(finalImageData)
                                                hasImageChanged = true
                                            }
                                        }
                                    }
                                }
                                // Clear selection after processing
                                selectedItems = []
                            }
                        }
                        
                        // Helper text with validation feedback
                        if existingImageURLs.isEmpty && newImagesData.isEmpty {
                            Text("⚠️ At least one image is required")
                                .font(.caption2)
                                .foregroundColor(.red)
                        } else {
                            Text("Tap photos to remove them • \(existingImageURLs.count + newImagesData.count) photo(s)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Capacity")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        TextField("e.g., 100 HP, 5 tons", text: $capacity)
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
                
                Section(header: Text("Pricing")) {
                    // Toggle for enabling discount pricing
                    Toggle("Provide Discount", isOn: $isDiscountEnabled)
                        .onChange(of: isDiscountEnabled) { newValue in
                            // When toggle is turned off, set real prices equal to display prices
                            if !newValue {
                                realPricePerHour = pricePerHour
                                realPricePerAcre = pricePerAcre
                                realPricePerHourError = nil
                                realPricePerAcreError = nil
                            }
                        }
                    
                    // Show Real Price per Hour only when discount is enabled
                    if isDiscountEnabled {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Real Price per Hour")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            HStack {
                                Text("₨")
                                    .foregroundColor(.secondary)
                                    .font(.headline)
                                TextField("0", value: $realPricePerHour, format: .number)
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
                    }
                    
                    // Price per Hour (always visible)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isDiscountEnabled ? "Display Price per Hour" : "Price per Hour")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        HStack {
                            Text("₨")
                                .foregroundColor(.secondary)
                                .font(.headline)
                            TextField("0", value: $pricePerHour, format: .number)
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
                    
                    // Show Real Price per Acre only when discount is enabled
                    if isDiscountEnabled {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Real Price per Acre")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            HStack {
                                Text("₨")
                                    .foregroundColor(.secondary)
                                    .font(.headline)
                                TextField("0", value: $realPricePerAcre, format: .number)
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
                    
                    // Price per Acre (always visible)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isDiscountEnabled ? "Display Price per Acre" : "Price per Acre")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        HStack {
                            Text("₨")
                                .foregroundColor(.secondary)
                                .font(.headline)
                            TextField("0", value: $pricePerAcre, format: .number)
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
                }
                
                Section(header: Text("Equipment Details")) {
                    // Location Picker with Map View
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
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
                    
                    // Model Year Picker
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Model Year")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Picker("Select Year", selection: $modelYear) {
                            ForEach((minYear...currentYear).reversed(), id: \.self) { year in
                                Text(String(year)).tag(String(year))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mileage")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        TextField("e.g., 50000 km, 1500 hrs", text: $mileage)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: mileage) { newValue in
                                validateMileage(newValue)
                            }
                        if let error = mileageError {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.top, 2)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        TextEditor(text: $description)
                            .frame(height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .onChange(of: description) { newValue in
                                if newValue.count > maxDescriptionLength {
                                    description = String(newValue.prefix(maxDescriptionLength))
                                }
                            }
                        HStack {
                            Spacer()
                            Text("\(description.count)/\(maxDescriptionLength)")
                                .font(.caption2)
                                .foregroundColor(description.count > maxDescriptionLength * 9/10 ? .orange : .secondary)
                        }
                    }
                }
                
                // Delete Equipment Section
                Section {
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Delete Equipment")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Edit Equipment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Only show Cancel button when presented modally (sheet)
                if isPresentedModally {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .disabled(isSaving)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if validateAllFields() {
                            saveEquipment()
                        }
                    }
                    .disabled(!isFormValid || isSaving || !hasDataChanged)
                }
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Delete Equipment", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            try await dataController.deleteEquipment(id: equipment.equipmentID)
                            dismiss()
                        } catch {
                            errorMessage = error.localizedDescription
                            showingErrorAlert = true
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete this equipment? This action cannot be undone.")
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
            .onAppear {
                // Fetch additional images when view appears
                Task {
                    await loadAdditionalImages()
                }
            }
    }
    
    // MARK: - Helper Methods
    
    private func loadAdditionalImages() async {
        print("🔄 Loading images for equipment: \(equipment.equipmentID)")
        print("   Primary image from equipment: \(equipment.equipmentImage)")
        
        // Fetch additional images from equipmentMoreImages table
        let additionalImages = (try? await dataController.fetchEquipmentMoreImages(equipmentID: equipment.equipmentID)) ?? []
        print("📥 Fetched \(additionalImages.count) additional images from database")
        
        await MainActor.run {
            // Combine primary image with additional images
            var allImages: [String] = []
            if !equipment.equipmentImage.isEmpty {
                allImages.append(equipment.equipmentImage)
                print("   Added primary image to display")
            }
            allImages.append(contentsOf: additionalImages)
            
            print("✅ Total images to display: \(allImages.count)")
            for (index, url) in allImages.enumerated() {
                print("   Image \(index + 1): \(url)")
            }
            
            existingImageURLs = allImages
            originalImageURLs = allImages
            isLoadingImages = false
        }
    }
    
    private func saveEquipment() {
        isSaving = true
        Task {
            do {
                // Validate that at least one image exists
                let totalImages = existingImageURLs.count + newImagesData.count
                if totalImages == 0 {
                    await MainActor.run {
                        isSaving = false
                        errorMessage = "Equipment must have at least one image. Please add a photo."
                        showingErrorAlert = true
                    }
                    return
                }
                
                // Upload new images if any were added
                var uploadedImageURLs: [String] = []
                
                if !newImagesData.isEmpty {
                    print("📤 Uploading \(newImagesData.count) new images...")
                    // Upload images one by one with error handling
                    for (index, imageData) in newImagesData.enumerated() {
                        do {
                            let imageURL = try await dataController.uploadEquipmentImage(imageData)
                            uploadedImageURLs.append(imageURL)
                            print("✅ Uploaded image \(index + 1): \(imageURL)")
                            
                            // Add small delay between uploads to avoid overwhelming the server
                            if index < newImagesData.count - 1 {
                                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                            }
                        } catch {
                            print("❌ Failed to upload image \(index + 1): \(error.localizedDescription)")
                            // Continue with other images even if one fails
                        }
                    }
                }
                
                // Combine existing images (not removed) with newly uploaded images
                let allImageURLs = existingImageURLs + uploadedImageURLs
                print("📸 Total images after combining: \(allImageURLs.count)")
                print("   Existing: \(existingImageURLs.count), Uploaded: \(uploadedImageURLs.count)")
                
                // Validate again after upload
                guard !allImageURLs.isEmpty else {
                    await MainActor.run {
                        isSaving = false
                        errorMessage = "Failed to upload images. Equipment must have at least one image."
                        showingErrorAlert = true
                    }
                    return
                }
                
                // Use first image as primary image for equipment table
                let primaryImageURL = allImageURLs.first!
                print("🎯 Primary image: \(primaryImageURL)")
                
                // Determine which images are additional (beyond the first)
                let additionalImages = Array(allImageURLs.dropFirst())
                print("📚 Additional images count: \(additionalImages.count)")
                
                // Update equipment with primary image
                try await dataController.updateEquipment(
                    id: equipment.equipmentID,
                    name: name,
                    type: type,
                    capacity: capacity,
                    pricePerHour: pricePerHour,
                    pricePerAcre: pricePerAcre,
                    location: location,
                    modelYear: modelYear,
                    mileage: mileage,
                    description: description,
                    equipmentImage: primaryImageURL
                )
                print("✅ Equipment updated with primary image")
                
                // Always update additional images if images changed
                if hasImageChanged {
                    print("🔄 Updating additional images...")
                    // Delete all existing additional images from equipmentMoreImages table
                    try await deleteAllAdditionalImages()
                    print("🗑️ Deleted old additional images")
                    
                    // Save new additional images to equipmentMoreImages table
                    if !additionalImages.isEmpty {
                        try await dataController.saveEquipmentMoreImages(
                            equipmentID: equipment.equipmentID,
                            imageUrls: additionalImages
                        )
                        print("✅ Saved \(additionalImages.count) additional images")
                    } else {
                        print("ℹ️ No additional images to save (only 1 image total)")
                    }
                }
                
                print("✅ Equipment saved successfully!")
                isSaving = false
                dismiss()
            } catch {
                print("❌ Error saving equipment: \(error.localizedDescription)")
                isSaving = false
                errorMessage = error.localizedDescription
                showingErrorAlert = true
            }
        }
    }
    
    private func deleteAllAdditionalImages() async throws {
        // Delete from equipmentMoreImages table
        try await dataController.getDatabase()
            .from("equipmentMoreImages")
            .delete()
            .eq("equipmentID", value: equipment.equipmentID.uuidString)
            .execute()
    }
    
    // MARK: - Validation Functions
    
    private var hasDataChanged: Bool {
        return name != equipment.name ||
               type != equipment.type ||
               capacity != equipment.capacity ||
               pricePerHour != equipment.pricePerHour ||
               pricePerAcre != equipment.pricePerAcre ||
               realPricePerHour != equipment.realPricePerHour ||
               realPricePerAcre != equipment.realPricePerAcre ||
               location != equipment.location ||
               modelYear != equipment.modelYear ||
               mileage != equipment.mielage ||
               description != (equipment.description ?? "") ||
               hasImageChanged
    }
    
    private var isFormValid: Bool {
        let baseValidation = nameError == nil && 
               capacityError == nil && 
               modelYearError == nil && 
               mileageError == nil &&
               pricePerHourError == nil &&
               pricePerAcreError == nil &&
               !name.isEmpty && 
               !capacity.isEmpty && 
               !modelYear.isEmpty &&
               pricePerHour >= 10 && pricePerHour <= 10000 &&
               pricePerAcre >= 100 && pricePerAcre <= 50000 &&
               (!existingImageURLs.isEmpty || !newImagesData.isEmpty) // At least 1 image required
        
        // If discount is enabled, also validate real prices
        if isDiscountEnabled {
            return baseValidation &&
                   realPricePerHourError == nil &&
                   realPricePerAcreError == nil &&
                   realPricePerHour >= 10 && realPricePerHour <= 10000 &&
                   realPricePerAcre >= 100 && realPricePerAcre <= 50000
        }
        
        return baseValidation
    }
    
    private func validateAllFields() -> Bool {
        validateName(name)
        validateCapacity(capacity)
        validatePricePerHour(pricePerHour)
        validatePricePerAcre(pricePerAcre)
        
        // Validate real prices if discount is enabled
        if isDiscountEnabled {
            validateRealPricePerHour(realPricePerHour)
            validateRealPricePerAcre(realPricePerAcre)
        }
        
        validateMileage(mileage)
        
        if !isFormValid {
            errorMessage = "Please fix all validation errors before saving"
            showingErrorAlert = true
            return false
        }
        return true
    }
    
    private func validateName(_ name: String) {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            nameError = "Equipment name is required"
        } else if name.count > maxNameLength {
            nameError = "Name must be less than \(maxNameLength) characters"
        } else if name.count < 2 {
            nameError = "Name must be at least 2 characters"
        } else {
            nameError = nil
        }
    }
    
    private func validateCapacity(_ capacity: String) {
        if capacity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            capacityError = "Capacity is required"
        } else if capacity.count > maxCapacityLength {
            capacityError = "Capacity must be less than \(maxCapacityLength) characters"
        } else if capacity.count < 2 {
            capacityError = "Capacity must be at least 2 characters"
        } else {
            capacityError = nil
        }
    }
    
    private func validatePricePerHour(_ price: Double) {
        if price < 10 {
            pricePerHourError = "Price per hour must be at least ₨10"
        } else if price > 10000 {
            pricePerHourError = "Price per hour must not exceed ₨10,000"
        } else {
            pricePerHourError = nil
        }
    }
    
    private func validatePricePerAcre(_ price: Double) {
        if price < 100 {
            pricePerAcreError = "Price per acre must be at least ₨100"
        } else if price > 50000 {
            pricePerAcreError = "Price per acre must not exceed ₨50,000"
        } else {
            pricePerAcreError = nil
        }
    }
    
    private func validateRealPricePerHour(_ price: Double) {
        if price < 10 {
            realPricePerHourError = "Real price per hour must be at least ₨10"
        } else if price > 10000 {
            realPricePerHourError = "Real price per hour must not exceed ₨10,000"
        } else {
            realPricePerHourError = nil
        }
    }
    
    private func validateRealPricePerAcre(_ price: Double) {
        if price < 100 {
            realPricePerAcreError = "Real price per acre must be at least ₨100"
        } else if price > 50000 {
            realPricePerAcreError = "Real price per acre must not exceed ₨50,000"
        } else {
            realPricePerAcreError = nil
        }
    }
    
    private func validateModelYear(_ yearString: String) {
        if yearString.isEmpty {
            modelYearError = "Model year is required"
            return
        }
        
        guard let year = Int(yearString) else {
            modelYearError = "Please enter a valid year"
            return
        }
        
        if year < minYear {
            modelYearError = "Year cannot be earlier than \(minYear)"
        } else if year > currentYear {
            modelYearError = "Year cannot be later than \(currentYear)"
        } else {
            modelYearError = nil
        }
    }
    
    private func validateMileage(_ mileage: String) {
        if mileage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            mileageError = "Mileage is required"
        } else if mileage.count > maxMileageLength {
            mileageError = "Mileage must be less than \(maxMileageLength) characters"
        } else {
            // Check if mileage contains only valid characters (numbers, decimals, units)
            let allowedCharacters = CharacterSet(charactersIn: "0123456789.,/ kmhrsmiles")
            if mileage.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
                mileageError = "Please enter valid mileage (e.g., 50000 km, 1500 hrs)"
            } else {
                mileageError = nil
            }
        }
    }
}