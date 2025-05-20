import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var dataController: DataController
    
    var body: some View {
        NavigationStack {
            Group {
                if dataController.completedServiceRequests.isEmpty {
                    ContentUnavailableView("No History", systemImage: "clock.arrow.circlepath", description: Text("Your completed service requests will appear here"))
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(dataController.completedServiceRequests, id: \.id) { request in
                                ServiceRequestRow(request: request, equipment: dataController.equipmentDetails[request.equipmentname])
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Service History")
            .task {
                do {
                    try await dataController.fetchCompletedServiceRequests()
                } catch {
                    print("Error fetching completed requests: \(error)")
                }
            }
        }
    }
} 
