import SwiftUI

struct AddEquipmentCardView: View {
    @State private var showingAddEquipment = false
    
    var body: some View {
        Button {
            showingAddEquipment = true
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add Equipment")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("List your equipment for service")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .sheet(isPresented: $showingAddEquipment) {
            AddEquipmentView()
        }
    }
}

#Preview {
    AddEquipmentCardView()
        .padding()
        .background(Color(.systemGray6))
} 