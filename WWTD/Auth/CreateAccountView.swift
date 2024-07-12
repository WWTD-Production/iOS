//
//  CreateAccountView.swift
//  WWTD
//
//  Created by Adrian Martushev on 6/27/24.
//


import SwiftUI


struct CreateAccountView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var currentUser : CurrentUserViewModel
    
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    @State var emailErrorMessage = ""
    @State var passwordErrorMessage = ""
    @State var confirmPasswordErrorMessage = ""

    @State var showErrorMessageModal = false
    @State var errorTitle = "Something went wrong"
    @State var errorMessage = "There seems to be an issue. Please try again or contact support if the problem continues \n\n www.tutortree.com/support"
    
    @State private var isLoading: Bool = false
    @State private var navigateToChooseSchool: Bool = false
    
    func formatErrorMessage(errorDescription : String) {
        switch errorDescription {
        case "The email address is already in use by another account." :
            errorTitle = "Email in use"
            errorMessage = "This email is already being used by another account. If this is you, please try logging in instead"
            
        case "The email address is badly formatted." :
            errorTitle = "Invalid Email"
            errorMessage = "There's an issue with your email. Please ensure it's formatted correctly"
            
        case "The password must be 6 characters long or more." :
            errorTitle = "Insecure Password"
            errorMessage = "Please choose a password with 6 characters or more."
            
        default :
            errorTitle = "Something went wrong"
            errorMessage = "There seems to be an issue. Please try again or contact support if the problem continues \n\n www.tutortree.com/support"
        }
    }
    
    
    private func createAccount() {
        withAnimation {
            //Reset errors every attempt
            emailErrorMessage = ""
            passwordErrorMessage = ""
            confirmPasswordErrorMessage = ""
            
            if email == "" {
                emailErrorMessage = "Please enter an email"
                
            } else if password.isEmpty {
                passwordErrorMessage = "Please choose a password"
                
            } else if confirmPassword.isEmpty {
                confirmPasswordErrorMessage = "Please confirm your password"
                
            } else if password != confirmPassword {
                confirmPasswordErrorMessage = "Your passwords don't match"
                
            } else {
                isLoading = true

                currentUser.createUserFromEmail(email: email, password: password) { success, errorMessage in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // Ensure minimum 2 seconds loading
                        isLoading = false
                        if success {
                            navigateToChooseSchool = true
                        } else {
                            showErrorMessageModal = true
                            formatErrorMessage(errorDescription: errorMessage)
                        }
                    }
                }
            }
        }

    }
    
    var body: some View {
        
        ZStack {
            
            VStack(spacing : 0) {
                
                ZStack {
                    HStack {
                        Button(action: {
                            self.presentationMode.wrappedValue.dismiss()
                            generateHapticFeedback()

                        }) {
                            Image(systemName: "arrow.left")
                                .font(Font.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                                .opacity(0.7)
                                .frame(width: 40, height: 40)
                        }
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("Create Account")
                            .font(.custom("Quicksand-Regular", size: 34))
                    }
                }
                .padding(.bottom, 30)
                .navigationTitle("")
                .navigationBarHidden(true)

                Spacer().frame(height: 20)
                
                
                
                VStack {
                    AccountCreationField(text: $email, title: "Email", placeholder: "example@email.com")
                    PasswordCreationField(text: $password, title: "Password", placeholder: "***********", isRequired: false)
                    PasswordCreationField(text: $confirmPassword, title: "Confirm Password", placeholder: "***********", isRequired: false)
                    
                    Button(action: {
                        self.createAccount()
                    }, label: {
                        HStack {
                            Spacer()
                            
                            Text("Create Account")
                                .foregroundColor(.white)
                                .font(.custom("Quicksand-Regular", size: 16))

                            Spacer()
                        }
                        .frame( height: 44)
                        .background(.black)
                        .cornerRadius(8)

                    })
                    .padding(.top)
                    
                    HStack {
                        Rectangle()
                            .frame(height : 1)
                            .frame(maxWidth : .infinity)
                            .foregroundColor(.black.opacity(0.3))
                        
                        Text("OR")
                            .padding(.horizontal)
                            .font(.custom("Quicksand-Regular", size: 12))
                        Rectangle()
                            .frame(height : 1)
                            .frame(maxWidth : .infinity)
                            .foregroundColor(.black.opacity(0.3))
                    }
                    .padding(.vertical)
                    
                    LoginOptionsView(buttonString: "Sign Up", email: $email, password: $password, errorTitle: $errorTitle, errorMessage: $errorMessage, showErrorMessage: $showErrorMessageModal)
                }
                .padding()
                .background(.thinMaterial)
                .cornerRadius(8)
                .shadow(radius: 5, x: 0, y: 5)
                .padding(.top, 24)
                
                Spacer()
                
            }
            .padding()
            .overlay {
                if isLoading {
                    LoadingView()
                        .edgesIgnoringSafeArea(.all)
                } else {
                    Color.black.opacity(showErrorMessageModal ? 0.5 : 0)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            withAnimation {
                                showErrorMessageModal = false
                            }
                        }
                }
            }
            
            VStack {
                Spacer()
                ErrorMessageModal(showErrorMessageModal: $showErrorMessageModal, title: errorTitle, message: errorMessage)
                    .centerGrowingModal(isPresented: showErrorMessageModal)
                Spacer()
            }
        }
    }
}



struct LoadingView: View {
    @State private var isAnimating = false

    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
            
            VStack {
                ProgressView()

                
                Text("Creating your account..")
                    .font(.system( size: 18, weight : .semibold ))
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                    .padding(.vertical)
                    .multilineTextAlignment(.center)
                
            }
            .frame(width : 250, height : 250)
            .background(.regularMaterial)
            .cornerRadius(15)
        }
    }
}





#Preview {
    CreateAccountView()
        .environmentObject(CurrentUserViewModel())
}

