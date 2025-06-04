//import SwiftUI
//import AuthenticationServices
//
//struct SignInView: View {
//    @StateObject private var viewModel = SignInWithAppleViewModel()
//    @State private var selectedTab = 0
//    
//    var body: some View {
//        NavigationStack {
//            VStack {
//                Spacer()
//                
//                // Logo or app name
//                Text("iKisan Service Provider")
//                    .font(.largeTitle)
//                    .fontWeight(.bold)
//                    .padding(.bottom, 50)
//                
//                // Sign in with Apple button
//                SignInWithAppleButton(.signIn) { request in
//                    viewModel.signIn()
//                } onCompletion: { result in
//                    // Handle completion in the view model
//                }
//                .signInWithAppleButtonStyle(.black)
//                .frame(height: 50)
//                .padding(.horizontal, 40)
//                
//                if viewModel.isLoading {
//                    ProgressView()
//                        .padding()
//                }
//                
//                if let error = viewModel.errorMessage {
//                    Text(error)
//                        .foregroundColor(.red)
//                        .padding()
//                }
//                
//                Spacer()
//            }
//            .navigationDestination(isPresented: $viewModel.navigateToHome) {
//                HomeView(selectedTab: $selectedTab)
//            }
//        }
//    }
//} 
