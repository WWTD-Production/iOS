//
//  AccountItemViews.swift
//  WWTD
//
//  Created by Adrian Martushev on 6/27/24.
//


import SwiftUI
import UIKit



struct AccountItemView : View {
    
    var baseColor : Color
    var icon : String
    var title : String
    
    @Binding var isOn : Bool
    
    var body: some View {
        HStack {
            ZStack {
                
                Circle()
                    .frame(width : 35, height : 35)
                    .foregroundStyle(
                        baseColor.gradient.shadow(.inner(color: .white.opacity(0.3), radius: 10, x: 3, y: 3))
                    )
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .font(.system(size: 15, weight: .bold))

            }
            
            Text(title)
                .foregroundColor(.black)
                .font(.custom("Day Roman", size: 16))
                .padding(.leading, 5)
                .foregroundStyle(.black)

            Spacer()
            
            CustomToggleView(isOn: $isOn, title: "test")
            
        }
        .padding(.bottom)
    }
}




struct AccountItemNavigationView : View {
    
    var baseColor : Color
    var icon : String
    var title : String
        
    var body: some View {
        HStack {
            ZStack {
                
                Circle()
                    .frame(width : 35, height : 35)
                    .foregroundStyle(
                        baseColor.gradient.shadow(.inner(color: .white.opacity(0.3), radius: 10, x: 3, y: 3))
                    )
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .font(.system(size: 15, weight: .bold))
            }
            
            Text(title)
                .font(.custom("Day Roman", size: 16))
                .padding(.leading, 5)
                .foregroundStyle(.black)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 18, weight: .light))
                .padding(.trailing, 5)
                .foregroundStyle(.black)


        }
        .padding(.bottom)
    }
}




struct CustomToggleView: View {
    @Binding var isOn: Bool
    var title : String

    var body: some View {
        Toggle("", isOn: $isOn)
            .toggleStyle(CustomToggleStyle())
    }
}


struct CustomToggleStyle: ToggleStyle {

    func makeBody(configuration: Configuration) -> some View {
        
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("\(configuration.isOn ? "wwtd-blue" : "logo-background")")
                    .shadow(.inner(color: .white.opacity(0.8), radius: 1, x: 0, y: -1))
                    .shadow(.inner(color: .black.opacity(0.3), radius: 2, x: 0, y: 2))
                )
                .frame(width: 50, height: 30)
                .overlay(
                    Circle()
                        .foregroundColor(.white)
                        .frame(height : 25)
                        .offset(x: configuration.isOn ? 10 : -10, y: 0)
                )
                .onTapGesture {
                    generateHapticFeedback()
                    withAnimation {
                        configuration.isOn.toggle()
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: configuration.isOn)

        }
    }
}

#Preview {
    VStack {
        VStack {
            AccountItemNavigationView(baseColor: .blue, icon: "calendar", title: "Navigation")
            AccountItemView(baseColor: .red, icon: "giftcard.fill", title: "Toggle", isOn: .constant(true))
        }
        .padding()
        .background(Color("background-element"))
        .cornerRadius(15)


    }        .padding()

    .background(Color("background"))
}

