//
//  AppManager.swift
//  WWTD
//
//  Created by Adrian Martushev on 6/27/24.


import Foundation
import UIKit

enum Tab: Int, Identifiable, CaseIterable, Comparable {
    static func < (lhs: Tab, rhs: Tab) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    case Home, Chat, Account
    
    internal var id: Int { rawValue }
    
    var icon: String {
        switch self {
        case .Home:
            return "magnifyingglass"
        case .Chat:
            return "calendar"
        case .Account:
            return "person.fill"

        }
    }

}

enum NavigationState {
    case initial, home
}

class AppManager : ObservableObject {
    static let shared = AppManager()
    
    init() {}

    @Published var navigationPath: [NavigationState] = [.initial]
    @Published var tabShowing: Tab = Tab.Home
    @Published var currentUserID = ""
    
    
    func navigateBack() {
        if navigationPath.count > 1 {
            navigationPath.removeLast()
        }
    }
    
    func popToRoot() {
        navigationPath = [.home]
    }
    
    func popToAccount() {
        // Navigate home first
        self.navigationPath = [.home]
        // Then switch to the Profile tab
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.tabShowing = .Account
        }
    }
    
    var isDarkMode: Bool {
        return UserDefaults.standard.bool(forKey: "isDarkMode")
    }
    
    func applyTheme(to window: UIWindow?) {
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
        }
    }
    
    func toggleTheme() {
        let currentMode = isDarkMode
        UserDefaults.standard.set(!currentMode, forKey: "isDarkMode")
        // Apply the theme to all windows
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                self.applyTheme(to: window)
            }
        }
    }
    
    func setDefaultTheme() {
        let userDefaults = UserDefaults.standard
        if userDefaults.object(forKey: "isDarkMode") == nil {
            // Default to dark mode
            print("No theme set, defaulting to dark mode")
            userDefaults.set(true, forKey: "isDarkMode")
        }
        // Apply the theme setting
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                self.applyTheme(to: window)
                print("isDarkMode : \(isDarkMode)")

            }
        }
    }
}
