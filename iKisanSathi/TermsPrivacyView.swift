//
//  TermsPrivacyView.swift
//  iKisanSathi
//
//  Created by harsh chauhan
//

import SwiftUI

struct TermsPrivacyView: View {
    var body: some View {
        List {
            Section(header: Text("Terms of Service").font(.headline).foregroundColor(.primary)) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Last Updated: July 25, 2025")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .padding(.bottom, 8)
                    
                    Group {
                        Text("1. Acceptance of Terms")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 4)
                        
                        Text("These Terms of Service (also called Terms & Conditions) govern your use of the iKisan mobile app. By downloading, accessing, or using iKisan, you agree to these terms. If you do not agree, you must not use the app. iKisan is provided for farmers and agricultural users in India; all users must comply with applicable laws and our policies.")
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 8)
                        
                        Text("2. Eligibility")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 4)
                        
                        Text("You must be at least 18 years old (or have legal parental consent if younger) to use the app. You also agree to provide accurate and up-to-date information during registration (name, contact, etc.) and to keep your account credentials secure. You are responsible for any activity under your account.")
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 8)
                        
                        Text("3. Service License")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 4)
                        
                        Text("iKisan grants you a limited, non-exclusive, non-transferable license to use the app for its intended purpose – browsing and renting farm equipment. You may not copy, modify, reverse engineer, or distribute the app or its content. All intellectual property rights (software, content, logos) remain with iKisan or its licensors.")
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 8)
                    }
                    
                    Group {
                        Text("4. User Obligations")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 4)
                        
                        Text("You agree to use iKisan in compliance with all applicable laws and these Terms. You must not engage in prohibited activities such as: uploading illegal, misleading, defamatory, or infringing content (reviews, images, messages); harassing or harming other users, or infringing their rights; using the app for unauthorized purposes (e.g. spamming, unauthorized data collection). If you post any content (equipment reviews, photos, etc.), you retain ownership but grant iKisan a worldwide license to use, display, and distribute it within the app. iKisan reserves the right to moderate, edit, or remove user content that violates rules.")
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 8)
                        
                        Text("5. Equipment Rental & Payment")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 4)
                        
                        Text("iKisan acts as a marketplace connecting you with third-party equipment providers. Any rental contract is directly between you and the equipment owner; iKisan merely facilitates introduction. We disclaim responsibility for the quality, safety, or performance of any rented equipment – you deal at your own risk. To pay for rentals, the app uses the Razorpay gateway. We do not collect your payment card details; Razorpay handles transactions. Your payment information (card, bank, UPI, etc.) and billing data (name, address, contact) are collected by Razorpay and shared with the equipment provider only with your consent. Razorpay's policies apply to those transactions. iKisan is not liable for any misuse of your payment data by third parties.")
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 8)
                        
                        Text("6. Pricing and Offers")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 4)
                        
                        Text("The equipment rental rates, discounts, and service fees displayed on iKisan are for reference. Final booking cost is confirmed at checkout. We may run special offers or group-booking discounts (Co-Equip), which you may avail of as per app promotions.")
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 8)
                    }
                    
                    Group {
                        Text("7. Disclaimers and Limitations")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 4)
                        
                        Text("iKisan is provided \"as is\" without warranties. We do not guarantee the app will be uninterrupted or error-free. We disclaim all implied warranties (merchantability, fitness for a particular purpose). iKisan is not liable for any indirect, incidental, or consequential damages arising from app use. We also disclaim liability for any action or omission of third-party equipment providers. For example, if an equipment is unavailable or damaged, iKisan is not responsible; the rental agreement and any dispute are between you and the provider. You agree to indemnify and hold iKisan harmless against all claims arising from your misuse of the app or violation of these Terms.")
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 8)
                        
                        Text("8. Termination")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 4)
                        
                        Text("We may suspend or terminate your account and access to iKisan at our discretion if you violate these Terms or for any unlawful conduct. Upon termination, your right to use the app ends. You can stop using the app anytime. If iKisan terminates your account, we will provide notice as appropriate.")
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 8)
                        
                        Text("9. Changes to Terms")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 4)
                        
                        Text("iKisan may modify these Terms of Service at any time (e.g. to comply with law or changes in service). We will notify you of significant changes via the app or email. Continued use after such changes means you accept the updated terms.")
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 8)
                        
                        Text("10. Governing Law and Dispute Resolution")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 4)
                        
                        Text("These Terms are governed by the laws of India. Any disputes arising hereunder shall be subject to the exclusive jurisdiction of the courts in India. By using the app, you consent to Indian law and venue.")
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 8)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("Privacy Policy").font(.headline).foregroundColor(.primary)) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Last Updated: July 25, 2025")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .padding(.bottom, 8)
                    
                    Group {
                        Text("1. Introduction")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 4)
                        
                        Text("iKisan respects your privacy and is committed to protecting your personal data. This Privacy Policy explains what information we collect, why we collect it, and how we use and share it. We comply with India's data protection laws (IT Act 2000 and forthcoming DPDP Act 2023) which require transparent, secure handling of personal data.")
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 8)
                        
                        Text("2. Information We Collect")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 4)
                        
                        Text("We collect only the information necessary to run the app and improve your experience. This includes: Account and Profile Data: When you register, we collect your name, email, phone number, password, and optionally your field size and crops grown. This helps personalize equipment recommendations. Location Data: With your permission, we access your device's GPS to suggest nearby equipment and to accurately add your farm address. This data is used in real time and not stored beyond what is needed for service. Booking Data: When you book equipment, we collect details like equipment type, date/time, and location. This helps iKisan and the provider fulfill the rental. User Content: You may upload photos of equipment and leave reviews. These images, ratings, and comments are visible to other users and providers. You retain ownership of your uploads, but by posting you grant iKisan a license to use them within the app. We review content for violations and remove any illegal material. Payment Data: We do not store your sensitive payment details. Payment processing is handled by Razorpay, which securely collects your card/bank details. We may receive transaction identifiers and billing info (name, address) from Razorpay for invoicing purposes, only with your consent. Technical/Usage Data: We automatically collect analytics data (IP address, device model, OS version, crash logs, etc.) to maintain and improve the app. We also collect app usage (searches, clicks) to personalize services.")
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 8)
                        
                        Text("3. How We Use Your Data")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 4)
                        
                        Text("Your information is used only for purposes listed at collection. Typical uses include: Providing and improving iKisan features (finding and booking equipment, recommending tools via AgriAssist). Personalizing content and suggestions based on your crops and location. Processing transactions (billing, payments via Razorpay). Communicating with you (booking confirmations, support queries, service updates). Enforcing our terms and preventing fraud or abuse. Complying with legal obligations (such as tax or financial recordkeeping). We implement \"reasonable security practices\" (encryption, strong passwords, regular audits) as required by law to protect your data.")
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 8)
                    }
                    
                    Group {
                        Text("4. Sharing Your Information")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 4)
                        
                        Text("We do not sell or rent your personal information to third parties. We only share data in the following ways: Service Providers: We use third-party services to operate iKisan. For example, we use Razorpay for payments (so they receive the necessary payment details with your consent) and Supabase (our Indian-hosted server) for data storage. These providers act as data processors and use your data only to provide those services under strict confidentiality. Equipment Providers: When you book equipment, we share necessary details (your name, address, booking dates, and any uploaded images) with the equipment owner to facilitate the rental. You consent to this sharing when you confirm a booking. Legal Requirements: We may disclose data if required by law or to protect our rights. For example, we may share information with authorities if we believe it is necessary to comply with a legal obligation or to prevent fraud/theft.")
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 8)
                        
                        Text("5. User Choices and Rights")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 4)
                        
                        Text("You have choices about your data. You can review or edit your profile information in the app's Profile section. By law, you may request access to your data, correction, or deletion of your personal information (as permitted). Upon your request, we will provide a copy of your data or delete it, subject to legal obligations. You can also withdraw your consent for certain processing by contacting us (see below). Any such request will be handled promptly in accordance with India's DPDP Act obligations.")
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 8)
                        
                        Text("6. Data Retention")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 4)
                        
                        Text("We retain your personal data only as long as needed for the purposes above, and as required by law. For example, booking records and transaction details may be kept for financial audit purposes. When data is no longer required, it is securely deleted or anonymized.")
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 8)
                        
                        Text("7. Security")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 4)
                        
                        Text("We protect your information with industry-standard security measures (SSL/TLS encryption, secure servers, regular audits). No system is completely secure, but we strive to exceed legal requirements. You are responsible for keeping your login credentials private. If you suspect unauthorized access to your account, contact us immediately.")
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 8)
                        
                        Text("8. Children's Data")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 4)
                        
                        Text("iKisan is intended for adult farmers and not for children under 18. We do not knowingly collect personal information from minors. If we learn that we have inadvertently collected a child's data, we will delete it.")
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 8)
                        
                        Text("9. Changes to Privacy Policy")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 4)
                        
                        Text("We may update this Privacy Policy from time to time (for example, if our features or legal obligations change). Significant changes will be notified to you within the app or via email. We encourage you to review this page periodically.")
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 8)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("Contact Information").font(.headline).foregroundColor(.primary)) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(Color(red: 0.298, green: 0.498, blue: 0.345))
                        Text("privacy@ikisan.com")
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    
                    Text("For any questions about these policies or to exercise your data rights, please contact our Data Protection Officer at privacy@ikisan.com. As required by the DPDP Act, we have designated a point of contact for data protection inquiries. We will respond to you within the timeframes mandated by law.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Terms & Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}
#Preview {
    NavigationView {
        TermsPrivacyView()
    }
}
