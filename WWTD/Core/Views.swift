//
//  Views.swift
//  Diddly
//
//  Created by Adrian Martushev on 6/21/24.
//

import SwiftUI

struct Views: View {
    @State var text = ""
    
    var body: some View {
        VStack {
            AccountCreationField( text: $text, title: "Email", placeholder: "example@email.com", isRequired: false)
            PasswordCreationField(text: $text, title: "Password", placeholder: "********", isRequired: false)
        }
        .padding()
    }
}




struct AccountCreationField : View {
    @EnvironmentObject var currentUser : CurrentUserViewModel
    
    @Binding var text : String
    var title : String
    var placeholder : String
    var isRequired : Bool = true
    
    var showError : Bool = false
    var errorMessage : String = "Error"
    
    var body: some View {
        VStack(alignment : .leading) {
            HStack(spacing : 2) {
                Text(title)
                    .font(.custom("Day Roman", size: 16))
                    .foregroundColor(.primary)
            }
            
            TextField("", text: $text, prompt: Text(verbatim: placeholder)
                .font(.custom("Day Roman", size: 14))
                .foregroundColor(.secondary))
                .font(.custom("Day Roman", size: 14))
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .padding(.leading, 16)
                .padding(.vertical, 13)
                .foregroundColor(.primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .inset(by: 0.5)
                        .stroke(Color(red: 0.07, green: 0.07, blue: 0.07).opacity(0.2), lineWidth: 1)
                )
                .background(.thinMaterial)
                .cornerRadius(4)
            
        }
        .padding(.top, 10)
        
    }
}


struct PasswordCreationField: View {
    @Binding var text: String
    var title: String
    var placeholder: String
    var isRequired : Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 2) {
                Text(title)
                    .font(.custom("Day Roman", size: 16))
                    .foregroundColor(.primary)
            }
            
            SecureField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .font(.custom("Day Roman", size: 14))
                .padding(.leading, 16)
                .padding(.vertical, 13)
                .foregroundColor(.primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .inset(by: 0.5)
                        .stroke(Color(red: 0.07, green: 0.07, blue: 0.07).opacity(0.2), lineWidth: 1)
                )
                .background(.thinMaterial)
                .cornerRadius(4)
        }
        .padding(.top, 10)
    }
}



struct LoginEmailTextField : View {
    
    @Binding var text : String
    @Binding var emailErrorMessage : String
    
    @State var isEditing = false

    
    var body: some View {
        
        
        VStack(alignment : .leading) {

            Text("Email")
                .font(.system( size: 18 ))
                .fontWeight(.medium)
            
            ZStack {
                
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color("background-textfield")
                        .shadow(.inner(color: .white.opacity(0.8), radius: 1, x: 0, y: -1))
                        .shadow(.inner(color: .black.opacity(0.3), radius: 2, x: 0, y: 2))
                    )
                    .frame(height : 50)
                    .cornerRadius(15)

                
                HStack {
                    
                    Image(systemName: "envelope.fill")
                        .foregroundColor(Color("placeholder"))
                        .padding(.trailing, 5 )
                        .padding(.leading)
                    
                    
                    if text == "" && !isEditing {
                    
                        Text(verbatim : "name@example.com")
                            .font(.custom("SF Pro", size: 16))
                            .foregroundColor(emailErrorMessage != "" ? .red : Color("placeholder"))
                            .fontWeight(.bold)
                    }
                    
                    
                    Spacer()
                }
                
                TextField("", text: $text)
                    .frame(height : 40)
                    .foregroundColor(.primary)
                    .padding(.leading, 50)
                    .onTapGesture {
                        isEditing = true
                    }
                    .onChange(of: text) { oldValue, newValue in
                        self.text = newValue.lowercased()
                    }
            }
            
            if emailErrorMessage != "" {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14, weight : .semibold))
                        .foregroundColor(.primary)

                    Text(emailErrorMessage)
                        .font(.system(size: 14, weight : .semibold))
                        .foregroundColor(.primary)

                }
                .padding(.leading)
                .transition(.opacity)
                .animation(.easeInOut, value: emailErrorMessage != "")

            }

        }
        .padding(.bottom, 30)
    }
}


#Preview {
    Views()
        .environmentObject(CurrentUserViewModel())
}
