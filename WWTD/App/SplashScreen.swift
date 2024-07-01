//
//  SplashScreen.swift
//  WWTD
//
//  Created by Adrian Martushev on 6/27/24.
//

import SwiftUI

struct SplashScreen: View {
    var body: some View {
        
        ZStack {
            
            Color("logo-background")
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width : 200, height : 200)
                
            }

        }

    }
}

#Preview {
    SplashScreen()
}
