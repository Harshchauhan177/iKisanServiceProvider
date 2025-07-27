//
//  AppInfoView.swift
//  iKisanSathi
//
//  Created by harsh chauhan
//

import SwiftUI

struct AppInfoView: View {
    private let ikisanGreen = Color(red: 0.298, green: 0.498, blue: 0.345)
    
    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image("iKisan")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(ikisanGreen)
                            .accessibility(label: Text("iKisan logo"))
                        
                        Text("iKisan")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Version 1.0.0 (Build 42)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 16)
            }
            
            Section(header: Text("Developer").font(.headline).foregroundColor(.primary)) {
                HStack {
                    Label {
                        Text("iKisan Technologies")
                    } icon: {
                        Image(systemName: "building.2.fill")
                            .foregroundColor(ikisanGreen)
                    }
                }
                
                Link(destination: URL(string: "https://www.ikisan.com")!) {
                    Label {
                        Text("www.ikisan.com")
                    } icon: {
                        Image(systemName: "globe")
                            .foregroundColor(ikisanGreen)
                    }
                }
                
                Link(destination: URL(string: "mailto:contact@ikisan.com")!) {
                    Label {
                        Text("contact@ikisan.com")
                    } icon: {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(ikisanGreen)
                    }
                }
            }
            
            Section(header: Text("Legal").font(.headline).foregroundColor(.primary)) {
                NavigationLink(destination: TermsPrivacyView()) {
                    Label {
                        Text("Terms & Privacy Policy")
                    } icon: {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(ikisanGreen)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("App Info")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        AppInfoView()
    }
}
