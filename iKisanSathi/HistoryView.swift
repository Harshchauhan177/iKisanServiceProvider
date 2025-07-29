import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var dataController: DataController
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                Group {
                    if dataController.completedServiceRequests.isEmpty {
                        ContentUnavailableView("No History", systemImage: "clock.arrow.circlepath", description: Text("Your completed service requests will appear here"))
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 24) {
                                ForEach(dataController.completedServiceRequests, id: \.id) { request in
                                    HStack {
                                        Spacer()
                                        ServiceRequestRow(request: request, equipment: dataController.equipmentDetails[request.equipmentname])
                                            .frame(maxWidth: 380)
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                        .refreshable {
                            await refreshHistoryData()
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
    
    private func refreshHistoryData() async {
        do {
            try await dataController.refreshAllData()
        } catch {
            print("Error refreshing history data: \(error)")
        }
    }
}
