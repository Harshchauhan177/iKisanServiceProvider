//
//  HelpCenterView.swift
//  iKisanSathi
//
//  Created by harsh chauhan
//

import SwiftUI

struct HelpCenterView: View {
    private let ikisanGreen = Color(red: 0.298, green: 0.498, blue: 0.345)
    @State private var searchText = ""
    
    var body: some View {
        List {
//            Section {
//                TextField("Search for help topics", text: $searchText)
//                    .padding(8)
//                    .background(Color(.systemGray6))
//                    .cornerRadius(8)
//            }
//            
            Section(header: Text("Frequently Asked Questions").font(.headline).foregroundColor(.primary)) {
                faqItem(question: "How do I add my equipment?", answer: "Go to the Home tab and tap on 'Add Equipment' button at the top. Fill in the required details and upload images of your equipment.")
                
                faqItem(question: "How do I view service requests?", answer: "You can view all service requests in the 'Service' tab. Active requests will be shown by default.")
                
                faqItem(question: "How do I update my profile?", answer: "Go to the Profile tab and tap on 'Edit' in the top right corner. Make your changes and tap 'Save'.")
                
                faqItem(question: "How do I track my earnings?", answer: "You can view your earnings in the 'Income' section accessible from the Home tab or by tapping on the Income quick access button.")
            }
            
            Section(header: Text("Contact Support").font(.headline).foregroundColor(.primary)) {
                Link(destination: URL(string: "mailto:support@ikisan.com")!) {
                    Label {
                        Text("Email Support")
                    } icon: {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(ikisanGreen)
                    }
                }
                
                Link(destination: URL(string: "tel:+918865830411")!) {
                    Label {
                        Text("Call Support: +91 8865830411")
                    } icon: {
                        Image(systemName: "phone.fill")
                            .foregroundColor(ikisanGreen)
                    }
                }
                
                Link(destination: URL(string: "https://wa.me/8865830411")!) {
                    Label {
                        Text("WhatsApp Support")
                    } icon: {
                        Image(systemName: "message.fill")
                            .foregroundColor(ikisanGreen)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Help Center")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func faqItem(question: String, answer: String) -> some View {
        DisclosureGroup {
            Text(answer)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.vertical, 8)
        } label: {
            Text(question)
                .font(.headline)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    NavigationView {
        HelpCenterView()
    }
}
