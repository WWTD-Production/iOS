//
//  InitialView.swift
//  WWTD
//
//  Created by Adrian Martushev on 6/27/24.
//

import SwiftUI
import Firebase
import FirebaseAuth
import GoogleSignIn
import UIKit
import AuthenticationServices
import CryptoKit



struct InitialView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State var email : String = ""
    @State var password : String = ""
    
    @State var showErrorMessageModal = false
    @State var errorTitle = "Something went wrong"
    @State var errorMessage = "There seems to be an issue. Please try again or contact support if the problem continues"
    
    @State var showPasswordResetModal = false
    @State var showTOS = false
    @State var showPP = false
    
    func formatErrorMessage(errorDescription : String) {
        switch errorDescription {
        case "The password is invalid or the user does not have a password." :
            errorTitle = "Invalid Password"
            errorMessage = "Either your password or email is incorrect, please try again."
            
        case "The email address is badly formatted." :
            errorTitle = "Invalid Email"
            errorMessage = "There's an issue with your email. Please ensure it's formatted correctly"
            
        case "There is no user record corresponding to this identifier. The user may have been deleted." :
            errorTitle = "No Account Found"
            errorMessage = "There's no account matching that information. Please check your email and try again"
            
        default :
            errorTitle = "Something went wrong"
            errorMessage = "There seems to be an issue. Please try again or contact support if the problem continues."
        }
    }
    
    func signInWithEmail() {
        //Check for new error states
        if email.isEmpty {
            withAnimation {
                errorMessage = "Please enter your email"
            }
        } else if password.isEmpty {
            withAnimation {
                errorMessage = "Please enter your password"
            }
        } else {
            
            Auth.auth().signIn(withEmail: email, password: password){ (authResult, error) in
                if let error = error {
                    withAnimation {
                        showErrorMessageModal = true
                        print( error)
                        formatErrorMessage(errorDescription: error.localizedDescription)
                    }
                    
                    return
                }
                print("Successfully authenticated user: \(Auth.auth().currentUser?.uid ?? "")")
                AppManager.shared.navigationPath = [.home]
            }
        }
    }

    var body: some View {

        ZStack {
            
            VStack {
                Spacer()
                
                VStack(spacing : 16) {
                    HStack {
                        Image("Logo")
                            .resizable()
                            .frame(width : 60, height : 60)
                            .clipShape(Circle())
                    }
                    .padding(.top)

                    AccountCreationField(text: $email, title: "Email", placeholder: "example@email.com")
                    PasswordCreationField(text: $password, title: "Password", placeholder: "***********", isRequired: false)
                    
                    HStack {
                        Spacer()
                        Button {
                            showPasswordResetModal = true
                        } label: {
                            Text("Forgot Password?")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        signInWithEmail()
                    }, label: {
                        HStack {
                            Spacer()
                            
                            Text("Login")
                                .foregroundColor(.white)
                                .font(.custom("Quicksand-Regular", size: 16))

                            Spacer()
                        }
                        .frame( height: 44)
                        .background(.black)
                        .cornerRadius(8)

                    })
                    .padding(.bottom)

                    
                    LoginOptionsView(buttonString: "Continue", email: $email, password: $password, errorTitle: $errorTitle, errorMessage: $errorMessage, showErrorMessage: $showErrorMessageModal)
                    
                    HStack {
                        Rectangle()
                            .frame(height : 1)
                            .frame(maxWidth : .infinity)
                            .foregroundColor(.black.opacity(0.3))
                        
                        Text("OR")
                            .padding(.horizontal, 5)
                            .font(.custom("Quicksand-Regular", size: 12))
                        
                        Rectangle()
                            .frame(height : 1)
                            .frame(maxWidth : .infinity)
                            .foregroundColor(.black.opacity(0.3))
                    }
                    
                    NavigationLink {
                        CreateAccountView()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Create an account")
                                .foregroundColor(.primary)
                                .font(.custom("Quicksand-Regular", size: 14))

                            Spacer()
                        }
                        .frame( height: 44)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                            .inset(by: 0.75)
                            .stroke(Color(.systemGray), lineWidth: 1.5)
                        )
                    }
                

                }
                .padding()
                .background(.thinMaterial)
                .cornerRadius(8)
                .shadow(radius: 5, x: 0, y: 5)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                Spacer()
                
                VStack {
                    Text("By continuing you agree to the")
                    HStack(spacing : 0) {
                        Button {
                            showTOS = true
                        } label: {
                            Text("Terms & Conditions").underline()
                        }
                        .foregroundColor(.blue)
                        
                        Text("and   ")
                        
                        Button {
                            showPP = true
                        } label: {
                            Text("Privacy Policy").underline()
                        }
                        .foregroundColor(.blue)
                    }
                }
                .font(Font.custom("Day Roman", size: 10))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .frame(width: 193, height: 40, alignment: .center)
                .padding(.bottom, 40)
            }
            .background(.regularMaterial)
            .overlay(
                Color.black.opacity(showErrorMessageModal || showPasswordResetModal ? 0.5 : 0)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            showPasswordResetModal = false
                            showErrorMessageModal = false
                        }
                    }
            )
            .onTapGesture {
                hideKeyboard()
            }
            .ignoresSafeArea(.keyboard)

            PasswordResetModal(showPasswordResetModal : $showPasswordResetModal)
                .centerGrowingModal(isPresented: showPasswordResetModal)
            
            ErrorMessageModal(showErrorMessageModal: $showErrorMessageModal, title: errorTitle, message: errorMessage)
                .centerGrowingModal(isPresented: showErrorMessageModal)
            
            TOSView(showTOS : $showTOS)
                .bottomUpSheet(isPresented: showTOS)
            
            PrivacyPolicyView(showPP : $showPP)
                .bottomUpSheet(isPresented: showPP)
            
        }
    }
}



struct LoginOptionsView : View {
    @EnvironmentObject var currentUser : CurrentUserViewModel
    
    @State var currentNonce: String?
    
    var buttonString : String
    @State var showEmailLogin = false

    @Binding var email : String
    @Binding var password : String
    @Binding var errorTitle : String
    @Binding var errorMessage : String
    @Binding var showErrorMessage : Bool
    
    func formatErrorMessage(errorDescription : String) {
        switch errorDescription {
        case "The password is invalid or the user does not have a password." :
            errorTitle = "Invalid Password"
            errorMessage = "Either your password or email is incorrect, please try again."
            
        case "The email address is badly formatted." :
            errorTitle = "Invalid Email"
            errorMessage = "There's an issue with your email. Please ensure it's formatted correctly"
            
        case "There is no user record corresponding to this identifier. The user may have been deleted." :
            errorTitle = "No Account Found"
            errorMessage = "There's no account matching that information. Please check your email and try again"
            
        default :
            errorTitle = "Something went wrong"
            errorMessage = "There seems to be an issue. Please try again or contact support if the problem continues"
        }
    }
    
    func getRootViewController() -> UIViewController? {
        return UIApplication.shared.windows.first?.rootViewController
    }
    
    func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        if let presentingViewController = getRootViewController() {
            
            GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [ self] result, error in
                if let error = error {
                    self.showErrorMessage = true
                    self.errorMessage = error.localizedDescription
                    return
                }
                guard let user = result?.user,
                      let idToken = user.idToken?.tokenString

                else {
                    return
                }

                currentUser.user.email = user.profile?.email ?? ""
                currentUser.user.name = user.profile?.name ?? ""
                
                let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                               accessToken: user.accessToken.tokenString)

                // Sign in with Firebase
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        self.showErrorMessage = true
                        self.errorMessage = error.localizedDescription
                        return
                    }
                    
                    
                    if let user = authResult?.user {
                        // Successfully authenticated with Firebase. Now fetch or create user profile.
                        let usersRef = Firestore.firestore().collection("users").document(user.uid)
                        
                        usersRef.getDocument { (document, error) in
                            if let document = document, document.exists {
                                print("User already exists in Firestore.")
                            } else {
                                // Create a new user document in Firestore
                                let newUser = [
                                    "id" : currentUser.currentUserID,
                                    "name":  user.displayName ?? "",
                                    "email": user.email ?? "",
                                    "profilePhoto": user.photoURL?.absoluteString ?? ""
                                ]
                                usersRef.setData(newUser) { error in
                                    if let error = error {
                                        self.showErrorMessage = true
                                        self.errorMessage = "Failed to create user document: \(error.localizedDescription)"
                                    } else {
                                        print("User document successfully created in Firestore.")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing : 20) {
            Button(action: {
                signInWithGoogle()
            }, label: {
                HStack {
                    Spacer()
                    Image("google-logo")
                        .resizable()
                        .scaledToFill()
                        .frame(width : 20, height : 20)
                    
                    Text("\(buttonString) with Google")
                        .foregroundColor(.primary)
                        .font(.custom("Quicksand-Regular", size: 14))
                    Spacer()
                }
                .frame( height: 44)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                    .inset(by: 0.75)
                    .stroke(Color(.systemGray), lineWidth: 1.5)

                )
            })
            
            Button(action: {
                currentUser.startSignInWithAppleFlow { success, error in
                    if success {
                        print("Successfully authenticated with Apple")
                        // Proceed with any follow-up actions, like checking Firestore for the user
                    } else if let error = error {
                        print("Authentication failed with error: \(error.localizedDescription)")
                    }
                }
            }, label: {
                HStack {
                    Spacer()
                    Image("facebook-logo")
                        .resizable()
                        .foregroundColor(.primary)
                        .scaledToFill()
                        .frame(width : 20, height : 20)
                    
                    Text("\(buttonString) with Facebook")
                        .foregroundColor(.primary)
                        .font(.custom("Quicksand-Regular", size: 14))

                    Spacer()
                }
                .frame( height: 44)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                    .inset(by: 0.75)
                    .stroke(Color(.systemGray), lineWidth: 1.5)

                )
            })
                        
        
        }
        
    }
}




#Preview {
    InitialView()
}

