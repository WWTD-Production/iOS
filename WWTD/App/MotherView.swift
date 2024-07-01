//
//  ContentView.swift
//  Diddly
//
//  Created by Adrian Martushev on 6/20/24.
//

import SwiftUI

struct MotherView: View {
    @EnvironmentObject var appManager: AppManager
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    @EnvironmentObject var currentUser: CurrentUserViewModel
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                NavigationStack(path: $appManager.navigationPath) {
                    EmptyView()
                        .navigationDestination(for: NavigationState.self) { index in
                            switch index {
                            case .initial:
                                InitialView()
                            case .home:
                                HomeView()
                            }
                        }
                }
            }
            .animation(.default, value: keyboardResponder.isKeyboardVisible)
            .onAppear {
                currentUser.listen()
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showSplash = false
                }
            }
            .onChange(of: currentUser.currentUserID) { oldValue, newValue in
                if newValue.isEmpty {
                    appManager.navigationPath = [.initial]
                } else {
                    appManager.navigationPath = [.home]
                }
            }
            
            
            
            if showSplash {
                SplashScreen()
                    .transition(.opacity)
                    .animation(.easeInOut, value: showSplash)
            }
        }
    }
}



fileprivate struct TabsLayoutView: View {

    @Binding var selectedTab: Tab
    @Namespace var namespace
    
    var body: some View {
        HStack {
            Spacer(minLength: 0)
            
            TabButton(tab: .Home, selectedTab: $selectedTab, namespace: namespace)
                .frame(width: 40, height: 40, alignment: .center)
                .padding(.top, 10)
            
            Spacer(minLength: 0)
            
            TabButton(tab: .Chat, selectedTab: $selectedTab, namespace: namespace)
                .frame(width: 40, height: 40, alignment: .center)
                .padding(.top, 10)
            
            Spacer(minLength: 0)
            
            TabButton(tab: .Account, selectedTab: $selectedTab, namespace: namespace)
                .frame(width: 40, height: 40, alignment: .center)
                .padding(.top, 10)
            
            Spacer(minLength: 0)
        }
        .frame(height: 60, alignment: .center)
        .background(.regularMaterial)
    }
    
    private struct TabButton: View {
        let tab: Tab
        @Binding var selectedTab: Tab
        var namespace: Namespace.ID
        @EnvironmentObject var appManager: AppManager

        var body: some View {
            Button {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.9, blendDuration: 0.6)) {
                    selectedTab = tab
                    appManager.navigationPath = [.home]
                }
            } label: {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .overlay(content: {
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width : 60, height : 50)
                            })
                            .matchedGeometryEffect(id: "Selected Tab", in: namespace)
                    }
                    
                    VStack (spacing : 0) {
                        Image(systemName: tab.icon)
                            .foregroundColor(selectedTab == tab ? .white : .secondary )
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .scaleEffect(isSelected ? 1 : 0.9)
                            .animation(isSelected ? .spring(response: 0.5, dampingFraction: 0.3, blendDuration: 1) : .spring(), value: selectedTab)
                        
                        Text("\(tab)")
                            .font(.custom("Comfortaa-Bold", size: 10))
                            .foregroundColor(selectedTab == tab ? .white : .secondary )
                            .padding(.top, 5)
                    }
                    .frame(width : 70, height : 55)
                    
                }
                .foregroundColor(.green)
            }
        }
        
        private var isSelected: Bool {
            selectedTab == tab
        }
    }
}


#Preview {
    MotherView()
        .environmentObject(AppManager())
        .environmentObject(CurrentUserViewModel())
        .environmentObject(KeyboardResponder())

}
