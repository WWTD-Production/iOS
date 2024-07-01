//
//  PasswordResetModal.swift
//  WWTD
//
//  Created by Adrian Martushev on 6/27/24.
//


import SwiftUI
import FirebaseAuth


struct PasswordResetModal : View {
    @Binding var showPasswordResetModal : Bool
    
    @State var email : String = ""
    @State var isEditing = false
    @State var emailError = false
    @State var emailSent = false
    
    @Environment(\.openURL) var openURL

    var body: some View {
        VStack(spacing : 0) {
            HStack {
                Button {
                    showPasswordResetModal = false

                } label: {
                    Image(systemName : "xmark")
                        .foregroundColor(.primary)
                        .opacity(0.7)
                        .frame(width: 30, height: 30)
                }
                Spacer()
                
                if !emailSent {
                    Text("Forgot Password?")
                        .font(.system(size: 18, weight : .bold))
                        .foregroundColor(.primary)
                        .offset(x : -10)
                }

                Spacer()

            }
            .padding()
            
            if emailSent {
                VStack(alignment: .center, spacing : 0) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.primary)
                        .padding(.bottom, 10)
                    
                    Text("Successfully Sent!")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    VStack {
                        Text("You'll receive instructions shortly. If you need further assistance please contact support at the link below\n ")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            openURL(URL(string: "https://www.tutortree.com/support")!)
                        }) {
                            Text(verbatim : "https://www.tutortree.com/support")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        
                    }
                    .padding()
                    .padding(.bottom)

                }
                .transition(.opacity)
                .animation(.easeInOut, value: emailSent)
                
                
            } else {
                Text("Enter your email below and we'll send you a link to reset your password.")
                    .font(.system(size: 14, weight : .medium))
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                
                
                AccountCreationField(text: $email, title: "Email address", placeholder: "email@school.edu", isRequired: false)
                    .keyboardType(.alphabet)
                    .padding()

                
                HStack(spacing : 15) {
                    
                    
                    Button {
                        if email == "" {
                            emailError = true
                        } else {
                            Auth.auth().sendPasswordReset(withEmail: email) { error in

                                if let error = error {
                                    print(error.localizedDescription)
                                }
                                
                                withAnimation {
                                    emailSent = true
                                    print("Password reset email sent to : \(email)")
                                }
                            }
                        }
                    } label: {
                        HStack(spacing : 0) {
                            
                            Text("Send Password Reset")
                                .font(.system(size : 16, weight : .bold))
                                .foregroundColor(.white)
                        }
                        .frame( width : 200, height : 40)
                        .background(.green)
                        .cornerRadius(10)
                    }

                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
            }

        }
        .frame(width : 350)
        .background(.regularMaterial)
        .cornerRadius(15)
    }
}

#Preview {
    PasswordResetModal(showPasswordResetModal: .constant(true))
}

