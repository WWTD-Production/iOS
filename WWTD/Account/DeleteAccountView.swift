//
//  DeleteAccountView.swift
//  TutorTree4
//
//  Created by Adrian Martushev on 2/11/24.
//

import SwiftUI


struct DeleteAccountView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var currentUser : CurrentUserViewModel
    
    
    @State var currentPassword : String = ""
    
    
    @State var showErrorMessageModal = false
    @State var errorTitle = "Something went wrong"
    @State var errorMessage = "There seems to be an issue. Please try again or contact support if the problem continues \n\n www.tutortree.com/support"
    
    
    func formatErrorMessage(errorDescription : String) {
        switch errorDescription {
        case "The password is invalid or the user does not have a password." :
            errorTitle = "Incorrect Password"
            errorMessage = "Your password is incorrect. Please try again"
            
        case "The email address is badly formatted." :
            errorTitle = "Invalid Email"
            errorMessage = "There's an issue with your email. Please ensure it's formatted correctly"
            
        default :
            errorTitle = "Something went wrong"
            errorMessage = "There seems to be an issue. Please try again or contact support if the problem continues."
        }
    }
    
    var body: some View {
        
        ZStack {
            VStack {
                VStack(alignment : .leading) {
                    HStack(spacing: 0) {
                        Button(action: {
                            self.presentationMode.wrappedValue.dismiss()
                            generateHapticFeedback()

                        }) {
                            Image(systemName: "arrow.left")
                                .font(Font.system(size: 16, weight: .semibold))
                                .foregroundStyle(.black)
                                .opacity(0.7)
                                .frame(width: 40, height: 40)

                        }
                        
                        Text("Delete Account")
                            .font(.custom("Day Roman", size: 24))
                            .padding(.horizontal)
                        
                        
                    }
                    .navigationTitle("")
                    .navigationBarHidden(true)
                    
                    
                    
                    
                    VStack {

                        VStack {
                            HStack (alignment:.top) {
                                
                                Image(systemName : "exclamationmark.triangle.fill")
                                    .font(.system(size: 14, weight: .regular))
                                    .offset(y : 3)
                                
                                Text("Account deletion is permanent and can't be undone. To continue, please verify your password:")
                                    .font(.custom("Day Roman", size: 16))
                            }
                            .padding(.bottom)
                            
                            PasswordCreationField(text: $currentPassword, title: "Current Password", placeholder: "********", isRequired: false)
                            
                            Spacer().frame(height : 20)
   
                            HStack {
                                Spacer()
                                
                                Button {
//                                    currentUser.deleteUserAccount(currentPassword: currentPassword) { success, errorMessage in
//                                        if success {
//                                            // Handle success (e.g., navigate back or show a success message)
//                                            withAnimation {
//                                                AppManager.shared.navigationPath = [.initial]
//                                            }
//                                            
//                                        } else {
//                                            // Handle failure (e.g., show an error message)
//                                            print(errorMessage?.localizedDescription ?? "")
//                                            formatErrorMessage(errorDescription: errorMessage?.localizedDescription ?? "Unknown error")
//                                            withAnimation {
//                                                showErrorMessageModal = true
//                                            }
//                                        }
//                                    }

                                } label: {
                                    
                                    HStack {
                                        Spacer()
                                        Image(systemName : "trash.fill")
                                            .font(.system(size: 16))
                                        
                                        Text("Confirm")
                                            .font(.system(size: 16))
                                        Spacer()

                                    }
                                    .foregroundStyle(.white)
                                    .frame(height : 40)
                                    .background(.black)
                                    .cornerRadius(5)
                                }
                            }
                            .padding(.top)
                        }
                        .padding(30)
                    }
                    .background(.regularMaterial)
                    .cornerRadius(15)
                    .shadow(radius: 10, x : 5, y : 5)
                    
                    
                    Spacer()
                    HStack {
                        Spacer()
                        VStack {
                            Image("Logo Only")
                                .resizable()
                                .frame(width:60, height:60)
                            
                            
                            Text(verbatim : "support@wwtd.io")
                                .font(Font.custom("Day Roman", size: 12))
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                        }
                        
                        Spacer()
                    }
                }
                .padding()
                
                
            }
            .background {
                Color("background")
                    .edgesIgnoringSafeArea(.all)

            }
            .overlay(
                Color.black.opacity(showErrorMessageModal  ? 0.5 : 0)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            showErrorMessageModal = false
                        }
                    }
            )
            
            
            VStack {
                Spacer()
                ErrorMessageModal(showErrorMessageModal: $showErrorMessageModal, title: errorTitle, message: errorMessage)
                    .centerGrowingModal(isPresented: showErrorMessageModal)
                Spacer()
            }
        }
    }
}

#Preview {
    DeleteAccountView()
        .environmentObject(CurrentUserViewModel())
}
