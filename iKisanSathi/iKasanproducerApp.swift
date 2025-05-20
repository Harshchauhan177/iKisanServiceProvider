//
//  iKasanproducerApp.swift
//  iKasanproducer
//
//  Created by Ck Raj on 15/05/25.
//

import SwiftUI

@main
struct iKasanproducerApp: App {
    @StateObject private var dataController = DataController()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if dataController.isAuthenticated {
                    MainTabView()
                } else {
                    NavigationView {
                        LoginView()
                    }
                }
            }
            .environmentObject(dataController)
            .task {
                await dataController.checkSession()
            }
        }
    }
}
