import UIKit
import SwiftUI
import CoreLocation
import MapKit
import Combine

// Add enum to distinguish between different use cases
enum LocationPickerPurpose {
    case bookingLocation
    case addressUpdate
    case equipmentLocation
}

// Protocol for passing back location data
protocol BookingLocationPickerDelegate: AnyObject {
    func didUpdateLocation(latitude: Double, longitude: Double, address: String?)
}

// New protocol for address updates
protocol AddressUpdateLocationDelegate: AnyObject {
    func didSelectLocation(latitude: Double, longitude: Double, address: String?)
}

// Protocol for equipment location selection
protocol EquipmentLocationDelegate: AnyObject {
    func didSelectEquipmentLocation(latitude: Double, longitude: Double, address: String?)
}

class BookingLocationPickerViewController: UIViewController {
    
    weak var delegate: BookingLocationPickerDelegate?
    weak var addressDelegate: AddressUpdateLocationDelegate?
    weak var equipmentLocationDelegate: EquipmentLocationDelegate?
    private var initialLatitude: Double = 0.0
    private var initialLongitude: Double = 0.0
    private var initialAddress: String?
    private var purpose: LocationPickerPurpose = .bookingLocation
    
    init(latitude: Double, longitude: Double, address: String?, purpose: LocationPickerPurpose = .bookingLocation) {
        self.initialLatitude = latitude
        self.initialLongitude = longitude
        self.initialAddress = address
        self.purpose = purpose
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up navigation bar with appropriate title
        switch purpose {
        case .bookingLocation:
            title = "Update Location"
        case .addressUpdate:
            title = "Select Address Location"
        case .equipmentLocation:
            title = "Select Equipment Location"
        }
        
        // Add a Done button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneButtonTapped)
        )
        
        // Create a SwiftUI view for the location picker
        let locationPickerView = BookingLocationPickerView(
            initialLatitude: initialLatitude,
            initialLongitude: initialLongitude,
            initialAddress: initialAddress,
            parentViewController: self
        )
        
        // Create hosting controller for SwiftUI view
        let hostingController = UIHostingController(rootView: locationPickerView)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Add the hosting controller as a child view controller
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        // Set constraints to fill the view
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    @objc private func doneButtonTapped() {
        print("Done button tapped - attempting to pop from navigation controller")
        
        // Get the selected location from the location manager
        let locationManager = LocationManager.shared
        if let selectedLocation = locationManager.selectedLocation {
            // Use appropriate delegate based on purpose
            switch purpose {
            case .bookingLocation:
                delegate?.didUpdateLocation(
                    latitude: selectedLocation.latitude,
                    longitude: selectedLocation.longitude,
                    address: selectedLocation.address
                )
            case .addressUpdate:
                addressDelegate?.didSelectLocation(
                    latitude: selectedLocation.latitude,
                    longitude: selectedLocation.longitude,
                    address: selectedLocation.address
                )
            case .equipmentLocation:
                equipmentLocationDelegate?.didSelectEquipmentLocation(
                    latitude: selectedLocation.latitude,
                    longitude: selectedLocation.longitude,
                    address: selectedLocation.address
                )
            }
            
            // Log success to help with debugging
            print("Location updated: lat=\(selectedLocation.latitude), lon=\(selectedLocation.longitude), address=\(selectedLocation.address ?? "none")")
        } else {
            // Log error to help with debugging
            print("Error: No location selected when Done was tapped")
        }
        
        // Since this view controller is pushed onto the navigation stack (not presented modally),
        // we need to use popViewController instead of dismiss
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let navController = self.navigationController {
                print("Popping view controller from navigation stack")
                navController.popViewController(animated: true)
            } else {
                print("No navigation controller found, trying dismiss as fallback")
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}

// Singleton location manager for sharing location data
class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    // Selected location tuple
    @Published var selectedLocation: (latitude: Double, longitude: Double, address: String?)?
    
    // User location (if available)
    @Published var userLocation: CLLocation?
    
    private let locationManager = CLLocationManager()
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // Public method to request location permissions
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // Public method to start location updates
    func startLocationUpdates() {
        guard locationManager.authorizationStatus == .authorizedWhenInUse || 
              locationManager.authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        locationManager.startUpdatingLocation()
    }
    
    // Public method to check authorization status
    var authorizationStatus: CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }
}

// CLLocationManagerDelegate extension
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Store the most recent user location
        if let location = locations.last {
            userLocation = location
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }
}

// SwiftUI view for picking a location
struct BookingLocationPickerView: View {
    // Color constants
    private let ikisanGreen = Color(red: 0.298, green: 0.498, blue: 0.345)
    
    // Environment object for location manager
    @ObservedObject private var locationManager = LocationManager.shared
    
    // State properties
    @State private var region: MKCoordinateRegion
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var showSearchResults = false
    @State private var isReverseGeocodingInProgress = false
    @State private var pinLocation: CLLocationCoordinate2D?
    @State private var isSearching = false
    @State private var isSearchFieldFocused = false
    
    // Debounce search for better performance
    @State private var searchDebounceTask: DispatchWorkItem?
    @State private var mapMovementDebounceTask: DispatchWorkItem?
    
    // Cancellable for location updates - must be @State since we're in a struct
    @State private var cancellables = Set<AnyCancellable>()
    
    // Reference to parent view controller for communication
    private var parentViewController: BookingLocationPickerViewController?
    
    // Initializer
    init(initialLatitude: Double, initialLongitude: Double, initialAddress: String?, parentViewController: BookingLocationPickerViewController) {
        // Set up initial map region
        let initialCoordinate = CLLocationCoordinate2D(
            latitude: initialLatitude,
            longitude: initialLongitude
        )
        
        // Initialize region state
        _region = State(initialValue: MKCoordinateRegion(
            center: initialCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
        
        // Initialize pin location
        _pinLocation = State(initialValue: initialCoordinate)
        
        // Store parent view controller
        self.parentViewController = parentViewController
        
        // Initialize location manager with initial values
        locationManager.selectedLocation = (
            latitude: initialLatitude,
            longitude: initialLongitude,
            address: initialAddress
        )
    }
    
    var body: some View {
        ZStack {
            // Base map view layer
            ZStack {
                // Custom MapView to handle region changes
                MapViewWithRegionTracking(
                    region: $region,
                    annotationItems: pinLocation != nil ? [PinAnnotation(coordinate: pinLocation!)] : [],
                    markerTint: ikisanGreen,
                    onRegionChangeEnd: { newRegion in
                        // Update pin when map stops moving
                        let centerCoordinate = newRegion.center
                        pinLocation = centerCoordinate
                        updateSelectedLocation(coordinate: centerCoordinate)
                    }
                )
                .edgesIgnoringSafeArea([.top, .bottom, .leading, .trailing])
                
                // Add a tap gesture recognizer to allow setting the pin precisely
                .onTapGesture { tapLocation in
                    // We want to handle map taps only, not search bar taps
                    if !isSearchFieldFocused {
                        // Use current region center as the tap location
                        let centerCoordinate = region.center
                        pinLocation = centerCoordinate
                        updateSelectedLocation(coordinate: centerCoordinate)
                    }
                }
            }
            
            // Overlay elements on top of map
            VStack(spacing: 0) {
                // Search bar at the top
                searchBarView
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .background(Color(.systemBackground).opacity(0.95))
                    .zIndex(100) // Keep search on top
                
                // Search results below search bar
                if showSearchResults && !searchResults.isEmpty {
                    searchResultsView
                        .zIndex(99) // High z-index for results
                }
                
                Spacer()
                
                // Controls at bottom
                VStack(spacing: 16) {
                    // Selected address display
                    addressBar
                    
                    // My location button
                    Button(action: {
                        useCurrentLocation()
                    }) {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Use My Location")
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(ikisanGreen)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.bottom, 16)
                }
                .padding(.horizontal)
                .background(Color(.systemBackground))
            }
            
            // We don't need a center indicator as we'll use a proper pin
            // This follows standard Apple Maps behavior where the pin is placed directly
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside search
            if isSearchFieldFocused {
                isSearchFieldFocused = false
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                               to: nil,
                                               from: nil,
                                               for: nil)
            }
        }
    }
    
    // MARK: - UI Components
    
    // Search bar component
    private var searchBarView: some View {
        HStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 17, weight: .medium))
                    .frame(width: 24, height: 24)
                    .padding(.leading, 6)
                
                TextField("Search for location", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .onChange(of: searchText) { newValue in
                        if newValue.isEmpty {
                            // Clear results immediately when text is cleared
                            searchResults = []
                            showSearchResults = false
                        } else {
                            // Otherwise search with debounce
                            searchForPlaces()
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        searchResults = []
                        showSearchResults = false
                        isSearchFieldFocused = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 17))
                            .frame(width: 24, height: 24)
                    }
                    .padding(.trailing, 6)
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
    
    // Search results list
    private var searchResultsView: some View {
        VStack {
            // Background for the results list
            ZStack {
                Rectangle()
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 5)
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        // Section header
                        HStack {
                            Text("Results")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.top, 8)
                                .padding(.bottom, 4)
                            Spacer()
                        }
                        
                        // Results list
                        ForEach(searchResults, id: \.self) { item in
                            Button(action: {
                                selectSearchResult(item)
                            }) {
                                HStack {
                                    // Location pin icon
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(ikisanGreen)
                                        .font(.system(size: 22))
                                        .frame(width: 30, height: 30)
                                    
                                    // Address info
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name ?? item.placemark.title ?? "Unknown location")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                        
                                        Text(addressFromPlacemark(item.placemark))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                    // Chevron
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .contentShape(Rectangle()) // Make entire row tappable
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                                .padding(.leading, 45)
                        }
                    }
                }
            }
            .frame(maxHeight: 300) // Limit height
            .padding(.horizontal)
        }
    }
    
    // Address display bar
    private var addressBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Selected Location")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(ikisanGreen)
                
                if let address = locationManager.selectedLocation?.address {
                    Text(address)
                        .font(.subheadline)
                        .lineLimit(2)
                } else {
                    Text("Move the map to select a location")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Location Functions
    
    // Search for places based on user input with debouncing
    private func searchForPlaces() {
        // Cancel any previous search task
        searchDebounceTask?.cancel()
        
        // Clear results if search text is empty
        if searchText.isEmpty {
            // Clear results immediately
            DispatchQueue.main.async {
                searchResults = []
                showSearchResults = false
            }
            return
        }
        
        // Create a new debounced search task
        let task = DispatchWorkItem {
            // Store the search text to check if it changed during the delay
            let queryText = searchText
            
            // Configure search request
            let searchRequest = MKLocalSearch.Request()
            searchRequest.naturalLanguageQuery = queryText
            searchRequest.region = region
            searchRequest.resultTypes = [.address, .pointOfInterest]
            
            // Perform search
            let search = MKLocalSearch(request: searchRequest)
            search.start { response, error in
                // Ensure we're on the main thread for UI updates
                DispatchQueue.main.async {
                    // Only update if the search text hasn't changed
                    if queryText == searchText {
                        if let error = error {
                            print("Search error: \(error.localizedDescription)")
                            return
                        }
                        
                        if let response = response {
                            searchResults = response.mapItems
                            showSearchResults = !searchResults.isEmpty
                        }
                    }
                }
            }
        }
        
        // Store and execute with delay
        searchDebounceTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: task)
    }
    
    // Select a search result
    private func selectSearchResult(_ mapItem: MKMapItem) {
        let coordinate = mapItem.placemark.coordinate
        
        // Get the place name or address to show in search bar
        let displayName = mapItem.name ?? mapItem.placemark.title ?? addressFromPlacemark(mapItem.placemark)
        
        // Update map region with animation
        withAnimation {
            region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
        
        // Set pin at the selected location
        pinLocation = coordinate
        
        // Get address from placemark
        let address = addressFromPlacemark(mapItem.placemark)
        
        // Update location manager
        locationManager.selectedLocation = (
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            address: address
        )
        
        // Update UI state but keep the search text
        DispatchQueue.main.async {
            // Update search text to show the selected location name
            searchText = displayName
            // Hide results and keyboard
            isSearchFieldFocused = false
            showSearchResults = false
        }
    }
    
    // Update the selected location based on map center coordinate
    private func updateSelectedLocation(coordinate: CLLocationCoordinate2D) {
        // Only update if the new coordinate is significantly different from the current pin
        // This helps prevent excessive updates during minor map movements
        let shouldUpdate = pinLocation == nil || 
            (abs(pinLocation!.latitude - coordinate.latitude) > 0.0001 || 
             abs(pinLocation!.longitude - coordinate.longitude) > 0.0001)
        
        if shouldUpdate {
            // Set pin at the coordinate (if not already set)
            pinLocation = coordinate
            
            // Update the location manager's selected location with the new coordinates
            if var currentLocation = locationManager.selectedLocation {
                currentLocation.latitude = coordinate.latitude
                currentLocation.longitude = coordinate.longitude
                locationManager.selectedLocation = currentLocation
            } else {
                locationManager.selectedLocation = (
                    latitude: coordinate.latitude, 
                    longitude: coordinate.longitude, 
                    address: nil
                )
            }
            
            // Debounce the reverse geocoding requests to prevent throttling
            mapMovementDebounceTask?.cancel()
            
            // Create a local copy of coordinates to avoid capturing strongly
            let locationToGeocode = coordinate
            
            let task = DispatchWorkItem {
                // No weak self needed in struct
                reverseGeocode(coordinate: locationToGeocode)
            }
            
            mapMovementDebounceTask = task
            // Use a longer delay to reduce the number of geocoding requests
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: task)
        }
    }
    
    // Use the user's current location
    private func useCurrentLocation() {
        if let userLocation = locationManager.userLocation {
            // We already have user location from the existing locationManager
            withAnimation {
                region = MKCoordinateRegion(
                    center: userLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
            
            // Set pin at user's location
            pinLocation = userLocation.coordinate
            
            // Update selected location
            updateSelectedLocation(coordinate: userLocation.coordinate)
        } else {
            // Use the public methods to request location
            locationManager.startLocationUpdates()
        }
    }
    
    // Reverse geocoding to get address from coordinates
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        // Avoid multiple simultaneous geocoding requests
        if isReverseGeocodingInProgress { return }
        isReverseGeocodingInProgress = true
        
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                isReverseGeocodingInProgress = false
                
                if let error = error {
                    print("Reverse geocoding error: \(error.localizedDescription)")
                    return
                }
                
                if let placemark = placemarks?.first {
                    // Generate address string from placemark
                    let address = addressFromPlacemark(placemark)
                    
                    // Update location manager with address
                    if var currentLocation = locationManager.selectedLocation {
                        currentLocation.address = address
                        locationManager.selectedLocation = currentLocation
                    }
                }
            }
        }
    }
    
    // Convert placemark to address string
    private func addressFromPlacemark(_ placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        if let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        }
        
        if let subThoroughfare = placemark.subThoroughfare {
            // Add number to street
            if let lastComponent = components.indices.last {
                components[lastComponent] = "\(subThoroughfare) \(components[lastComponent])"
            } else {
                components.append(subThoroughfare)
            }
        }
        
        if let locality = placemark.locality {
            components.append(locality)
        }
        
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        
        if let postalCode = placemark.postalCode {
            components.append(postalCode)
        }
        
        if let country = placemark.country {
            components.append(country)
        }
        
        return components.joined(separator: ", ")
    }
}

// Pin annotation for the map
struct PinAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// Custom MapView implementation that properly tracks region changes
struct MapViewWithRegionTracking: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var annotationItems: [PinAnnotation]
    var markerTint: Color
    var onRegionChangeEnd: (MKCoordinateRegion) -> Void
    
    // Coordinator to handle MKMapView delegate calls
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewWithRegionTracking
        var isUserInteraction = false
        
        init(parent: MapViewWithRegionTracking) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            // Detect if this is user-initiated or programmatic
            if let gestureRecognizers = mapView.subviews.first?.gestureRecognizers {
                isUserInteraction = gestureRecognizers.contains { $0.state == .began || $0.state == .changed }
            }
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // Update the binding
            parent.region = mapView.region
            
            // Only notify for user-initiated changes to reduce unnecessary updates
            if isUserInteraction {
                parent.onRegionChangeEnd(mapView.region)
                isUserInteraction = false
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        
        // Add annotations for the pins
        updateAnnotations(for: mapView)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Only update the region if it's significantly different
        if abs(mapView.region.center.latitude - region.center.latitude) > 0.0001 ||
           abs(mapView.region.center.longitude - region.center.longitude) > 0.0001 ||
           abs(mapView.region.span.latitudeDelta - region.span.latitudeDelta) > 0.001 {
            mapView.setRegion(region, animated: true)
        }
        
        // Update annotations when they change
        updateAnnotations(for: mapView)
    }
    
    private func updateAnnotations(for mapView: MKMapView) {
        // Remove existing annotations
        let existingAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(existingAnnotations)
        
        // Add new annotations
        if !annotationItems.isEmpty {
            let mkAnnotations = annotationItems.map { item -> MKPointAnnotation in
                let annotation = MKPointAnnotation()
                annotation.coordinate = item.coordinate
                return annotation
            }
            mapView.addAnnotations(mkAnnotations)
        }
    }
}

// SwiftUI wrapper for the UIKit location picker
struct LocationPickerViewController_SwiftUI: UIViewControllerRepresentable {
    let latitude: Double
    let longitude: Double
    let address: String?
    let purpose: LocationPickerPurpose
    weak var delegate: EquipmentLocationDelegate?
    
    init(latitude: Double, longitude: Double, address: String?, purpose: LocationPickerPurpose, delegate: EquipmentLocationDelegate?) {
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.purpose = purpose
        self.delegate = delegate
    }
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let locationPicker = BookingLocationPickerViewController(
            latitude: latitude,
            longitude: longitude,
            address: address,
            purpose: purpose
        )
        locationPicker.equipmentLocationDelegate = delegate
        
        let navController = UINavigationController(rootViewController: locationPicker)
        return navController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // No updates needed for this implementation
    }
}

// SwiftUI wrapper for equipment location selection
struct EquipmentLocationPickerView: View {
    let latitude: Double
    let longitude: Double
    let address: String?
    let onLocationSelected: (Double, Double, String?) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            LocationPickerViewController_SwiftUI_Closure(
                latitude: latitude,
                longitude: longitude,
                address: address,
                purpose: .equipmentLocation,
                onLocationSelected: onLocationSelected
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Updated SwiftUI wrapper for the UIKit location picker using closures
struct LocationPickerViewController_SwiftUI_Closure: UIViewControllerRepresentable {
    let latitude: Double
    let longitude: Double
    let address: String?
    let purpose: LocationPickerPurpose
    let onLocationSelected: (Double, Double, String?) -> Void
    
    func makeUIViewController(context: Context) -> BookingLocationPickerViewController {
        let locationPicker = BookingLocationPickerViewController(
            latitude: latitude,
            longitude: longitude,
            address: address,
            purpose: purpose
        )
        
        // Create a coordinator to handle the callback
        let coordinator = context.coordinator
        coordinator.onLocationSelected = onLocationSelected
        locationPicker.equipmentLocationDelegate = coordinator
        
        return locationPicker
    }
    
    func updateUIViewController(_ uiViewController: BookingLocationPickerViewController, context: Context) {
        // No updates needed for this implementation
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, EquipmentLocationDelegate {
        var onLocationSelected: ((Double, Double, String?) -> Void)?
        
        func didSelectEquipmentLocation(latitude: Double, longitude: Double, address: String?) {
            onLocationSelected?(latitude, longitude, address)
        }
    }
}