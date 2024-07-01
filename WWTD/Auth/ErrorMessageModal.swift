//
//  ErrorMessageModal.swift
//  WWTD
//
//  Created by Adrian Martushev on 6/27/24.
//

import SwiftUI


struct ErrorMessageModal : View {
    @Binding var showErrorMessageModal : Bool
    
    var title : String
    var message : String
    
    
    var body: some View {
        VStack(spacing : 0) {
            HStack {
                Button {
                    showErrorMessageModal = false

                } label: {
                    Image(systemName : "xmark")
                        .foregroundColor(.primary)
                        .opacity(0.7)
                        .frame(width: 30, height: 30)
                }
                Spacer()
                
                Text(title)
                    .font(.system(size: 18, weight : .bold))
                    .foregroundColor(.primary)
                    .offset(x : -10)


                Spacer()

            }
            .padding()
            
            Text(verbatim: message)
                .font(.system(size: 14, weight : .medium))
                .foregroundColor(.primary)
                .padding(.horizontal)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            

            
            HStack(spacing : 15) {
                
                
                Button {
                    withAnimation {
                        showErrorMessageModal = false
                    }
                } label: {
                    HStack(spacing : 0) {
                        
                        Text("Ok")
                            .font(.system(size : 16, weight : .bold))
                            .foregroundColor(.white)
                    }
                    .frame( width : 200, height : 40)
                    .background(.black.opacity(0.8))
                    .cornerRadius(10)
                }

            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
        

        }
        .frame(width : 350)
        .background(.regularMaterial)
        .cornerRadius(15)
    }
}

#Preview {
    ErrorMessageModal(showErrorMessageModal: .constant(true), title: "Something went wrong", message: "There seems to be an issue. Please try again or contact support if the problem continues \n\n www.tutortree.com/support")
}
