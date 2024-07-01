//
//  TOSView.swift
//  WWTD
//
//  Created by Adrian Martushev on 6/27/24.
//

import SwiftUI

struct TOSView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var currentUser : CurrentUserViewModel
    
    var showTOS : Binding<Bool>?
    
    var body: some View {
        

        VStack {
            VStack(alignment : .leading) {
                HStack(spacing: 0) {
                    Button(action: {
                        if let showTOS = showTOS {
                            showTOS.wrappedValue = false
                        } else {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                        generateHapticFeedback()

                    }) {
                        Image(systemName: (showTOS != nil) ? "xmark" : "arrow.left")
                            .font(Font.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .opacity(0.7)
                            .frame(width: 40, height: 40)
                    }
                    
                    Text("Back")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                    .opacity(0.7)

                }
                .toolbar(.hidden)
                
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Terms of Service")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
                            .padding(.bottom)

                        Group {
                            Text("1. Terms Section Title")
                            
                            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
                        }

                        Group {
                            Text("1. Terms Section Title")
                            
                            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
                        }
                    }
                    .padding()
                }

            }
            .padding()
        }
        .background(.regularMaterial)
    }
    
    
}


#Preview {
    TOSView()
        .environmentObject(CurrentUserViewModel())
}
