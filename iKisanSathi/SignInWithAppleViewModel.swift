//
//  SignInWithAppleViewModel.swift
//  iKisanSathi
//
//  Created by harsh chauhan on 03/06/25.
//

import Foundation
import AuthenticationServices
import CryptoKit
import Supabase
import SwiftUI

class SignInWithAppleViewModel: NSObject, ObservableObject {
    @Published var isLoading = false
    @Published var isAuthenticated = false
    @Published var navigateToHome = false
    @Published var errorMessage: String?
    
    private var currentNonce: String?
    private var client: SupabaseClient!
    
    private enum UserDefaultsKeys {
        static let sessionKey = "supabase_session"
        static let userIdKey = "user_id"
        static let userEmailKey = "user_email"
    }
    
    override init() {
        super.init()
        self.client = SupabaseClient(
            supabaseURL: URL(string: "https://pxuuupiqeipyemluyers.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB4dXV1cGlxZWlweWVtbHV5ZXJzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUzMDUzMzQsImV4cCI6MjA2MDg4MTMzNH0.zH4zUtWuYB1YTzwIMx_Js6EgnI-s-3AV6WP0qsKjzZ8"
        )
        Task {
            await checkAndRestoreSession()
        }
    }
    
    private func checkAndRestoreSession() async {
        if let sessionString = UserDefaults.standard.string(forKey: UserDefaultsKeys.sessionKey),
           let sessionData = sessionString.data(using: .utf8) {
            do {
                let sessionDict = try JSONDecoder().decode([String: String].self, from: sessionData)
                if let accessToken = sessionDict["accessToken"],
                   let refreshToken = sessionDict["refreshToken"] {
                    do {
                        try await client.auth.setSession(accessToken: accessToken, refreshToken: refreshToken)
                        await MainActor.run {
                            self.isAuthenticated = true
                            self.navigateToHome = true
                            print("✅ Session restored")
                        }
                    } catch {
                        print("❌ Failed to set session: \(error)")
                        await clearSession()
                    }
                }
            } catch {
                print("❌ Failed to restore session: \(error)")
                await clearSession()
            }
        } else {
            print("❌ Failed to restore session: sessionMissing")
        }
    }
    
    private func saveSession(_ session: Session) async {
        do {
            let sessionDict = [
                "accessToken": session.accessToken,
                "refreshToken": session.refreshToken
            ]
            let sessionData = try JSONEncoder().encode(sessionDict)
            if let sessionString = String(data: sessionData, encoding: .utf8) {
                UserDefaults.standard.set(sessionString, forKey: UserDefaultsKeys.sessionKey)
                UserDefaults.standard.set(session.user.id.uuidString, forKey: UserDefaultsKeys.userIdKey)
                UserDefaults.standard.set(session.user.email, forKey: UserDefaultsKeys.userEmailKey)
                
                do {
                    try await client.auth.setSession(accessToken: session.accessToken, refreshToken: session.refreshToken)
                    await MainActor.run {
                        self.isAuthenticated = true
                        self.navigateToHome = true
                    }
                    print("✅ Session saved and set")
                } catch {
                    print("❌ Failed to set session: \(error)")
                    await clearSession()
                }
            }
        } catch {
            print("❌ Failed to save session: \(error)")
        }
    }
    
    private func clearSession() async {
        await MainActor.run {
            UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.sessionKey)
            UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.userIdKey)
            UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.userEmailKey)
            self.isAuthenticated = false
            self.navigateToHome = false
        }
    }

    func signIn() {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    func handleAppleSignIn(credential: ASAuthorizationAppleIDCredential) async {
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            await MainActor.run {
                self.errorMessage = "Failed to get Apple credentials"
            }
            return
        }

        let rawName = [credential.fullName?.givenName, credential.fullName?.familyName].compactMap { $0 }.joined(separator: " ")
        let finalName = rawName.isEmpty ? "iKisan Producer" : rawName
        
        print("📱 Apple Sign In - Constructed Name:", finalName)
        
        // Email might be nil after first sign in
        let rawEmail = credential.email ?? ""
        print("📱 Apple Sign In - Raw Apple Email:", rawEmail)
        print("📱 Apple Sign In - User ID:", credential.user)

        do {
            await MainActor.run { self.isLoading = true }
            
            print("🔄 Attempting Supabase Auth sign in...")
            let session = try await client.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: tokenString,
                    nonce: currentNonce
                )
            )

            print("✅ Supabase Auth Success:")
            print("   - User ID: \(session.user.id)")
            print("   - Email: \(session.user.email ?? "No email")")

            // Save the session
            await saveSession(session)

            // Always use email from Supabase session if Apple didn't provide it
            let finalEmail = rawEmail.isEmpty ? (session.user.email ?? "") : rawEmail

            if !finalEmail.isEmpty {
                do {
                    print("🔄 Attempting to upsert into Producer table...")
                    try await insertIntoProducerTable(
                        id: session.user.id,
                        name: finalName,
                        email: finalEmail
                    )
                    print("✅ Successfully upserted into Producer table")
                    
                    // Set authentication state
                    await MainActor.run {
                        self.isAuthenticated = true
                        self.navigateToHome = true
                        self.errorMessage = nil
                    }
                } catch let error as PostgrestError {
                    print("⚠️ Postgrest Error:", error.message)
                    if !error.message.contains("duplicate key value") {
                        await MainActor.run {
                            self.errorMessage = "Failed to save producer data: \(error.message)"
                        }
                    }
                }
            }
            
        } catch {
            print("❌ Sign-in error: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "Sign-in failed: \(error.localizedDescription)"
                self.isAuthenticated = false
                self.navigateToHome = false
            }
            await clearSession()
        }
        
        await MainActor.run { self.isLoading = false }
    }

    private func insertIntoProducerTable(id: UUID, name: String, email: String) async throws {
        print("🔄 Creating ProducerData with:")
        print("   - ID: \(id)")
        print("   - Name: \(name)")
        print("   - Email: \(email)")
        
        struct ProducerData: Encodable {
            let id: UUID
            let name: String
            let email: String
            let phone: String?
            let location: String?
            let rating: Double?
            let profileimage: String?
            let equipments: [String]?
            let accountNo: String?
            let ifcsCode: String?
        }

        let producerData = ProducerData(
            id: id,
            name: name,
            email: email,
            phone: nil,
            location: nil,
            rating: nil,
            profileimage: nil,
            equipments: nil,
            accountNo: nil,
            ifcsCode: nil
        )

        print("🔄 Executing database upsert...")
        try await client.database
            .from("producer")
            .upsert(producerData, onConflict: "id")
            .execute()
        print("✅ Database upsert completed")
    }

    // MARK: - Nonce Utilities

    private func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in UInt8.random(in: 0...255) }
            for random in randoms {
                if remainingLength == 0 { return result }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Apple Sign-In Delegates

extension SignInWithAppleViewModel: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = appleIDCredential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            self.errorMessage = "Failed to get Apple credentials"
            return
        }

        let rawName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName].compactMap { $0 }.joined(separator: " ")
        let finalName = rawName.isEmpty ? "iKisan Producer" : rawName
        
        print("📱 Apple Sign In - Constructed Name:", finalName)
        
        // Email might be nil after first sign in
        let rawEmail = appleIDCredential.email ?? ""
        print("📱 Apple Sign In - Raw Apple Email:", rawEmail)
        print("📱 Apple Sign In - User ID:", appleIDCredential.user)

        Task {
            do {
                await MainActor.run { self.isLoading = true }
                
                print("🔄 Attempting Supabase Auth sign in...")
                let session = try await client.auth.signInWithIdToken(
                    credentials: .init(
                        provider: .apple,
                        idToken: tokenString,
                        nonce: currentNonce
                    )
                )

                print("✅ Supabase Auth Success:")
                print("   - User ID: \(session.user.id)")
                print("   - Email: \(session.user.email ?? "No email")")

                // Save the session
                await saveSession(session)

                // Always use email from Supabase session if Apple didn't provide it
                let finalEmail = rawEmail.isEmpty ? (session.user.email ?? "") : rawEmail

                if !finalEmail.isEmpty {
                    do {
                        print("🔄 Attempting to upsert into Producer table...")
                        try await insertIntoProducerTable(
                            id: session.user.id,
                            name: finalName,
                            email: finalEmail
                        )
                        print("✅ Successfully upserted into Producer table")
                        
                        // Set authentication state
                        await MainActor.run {
                            self.isAuthenticated = true
                            self.navigateToHome = true
                            self.errorMessage = nil
                        }
                    } catch let error as PostgrestError {
                        print("⚠️ Postgrest Error:", error.message)
                        if !error.message.contains("duplicate key value") {
                            await MainActor.run {
                                self.errorMessage = "Failed to save producer data: \(error.message)"
                            }
                        }
                    }
                }
                
            } catch {
                print("❌ Sign-in error: \(error.localizedDescription)")
                await MainActor.run {
                    self.errorMessage = "Sign-in failed: \(error.localizedDescription)"
                    self.isAuthenticated = false
                    self.navigateToHome = false
                }
                await clearSession()
            }
            
            await MainActor.run { self.isLoading = false }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("❌ Apple Sign-In failed: \(error.localizedDescription)")
        self.errorMessage = "Apple Sign-In failed: \(error.localizedDescription)"
        self.isLoading = false
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
