import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    @State private var location = ""
    @State private var isEditingLocation = false
    
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dataController.currentUser?.email ?? "")
                            .font(.headline)
                        Text("Producer")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section {
                Button {
                    Task {
                        try? await dataController.signOut()
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.red)
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
    }
}
