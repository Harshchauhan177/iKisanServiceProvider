//
//  TermsPrivacyView.swift
//  iKisanSathi
//
//  Created by harsh chauhan
//

import SwiftUI

struct TermsPrivacyView: View {
    private let ikisanGreen = Color(red: 0.298, green: 0.498, blue: 0.345)
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("Terms of Service")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(ikisanGreen)
                    
                    Text("Last Updated: June 2025")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("1. Acceptance of Terms")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    Text("By accessing or using the iKisan application, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the application.")
                    
                    Text("2. Description of Service")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    Text("iKisan provides a platform connecting farmers with agricultural equipment providers. Our service facilitates the booking and management of agricultural equipment for farming purposes.")
                    
                    Text("3. User Accounts")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    Text("Users are responsible for maintaining the confidentiality of their account information and for all activities that occur under their account. Users must provide accurate and complete information when creating an account.")
                }
                
                Group {
                    Text("Privacy Policy")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(ikisanGreen)
                        .padding(.top, 30)
                    
                    Text("Last Updated: June 2025")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("1. Information We Collect")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    Text("We collect personal information such as name, email address, phone number, and location to provide our services. We also collect information about your equipment and booking history.")
                    
                    Text("2. How We Use Your Information")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    Text("We use your information to provide and improve our services, process transactions, communicate with you, and ensure the security of our platform.")
                    
                    Text("3. Data Security")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    Text("We implement appropriate security measures to protect your personal information from unauthorized access, alteration, disclosure, or destruction.")
                    
                    Text("4. Contact Us")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    Text("If you have any questions about our Terms of Service or Privacy Policy, please contact us at contact@ikisan.com.")
                }
            }
            .padding()
        }
        .navigationTitle("Terms & Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        TermsPrivacyView()
    }
}