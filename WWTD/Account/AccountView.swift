//
//  AccountView.swift
//  WWTD
//
//  Created by Adrian Martushev on 6/27/24.
//

import SwiftUI
import UIKit
import StoreKit


struct AccountView: View {
    @EnvironmentObject var currentUser : CurrentUserViewModel
    @EnvironmentObject var storeManager : StoreManager

    @Binding var showAccountView : Bool
    
    @State var showManageBalance = false
        
    func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium // This sets the style to "MMM d, yyyy"
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: date)
    }
    
    var body: some View {
        
        HStack {
            Spacer()
            
            VStack(alignment : .leading, spacing : 0) {
                
                HStack {
                    Button {
                        showAccountView = false
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.black.opacity(0.8))
                    }
                    Text("Account")
                        .font(.custom("Day Roman", size: 34))
                        .padding(.leading, 5)
                    
                    Spacer()
                    
                }
                .padding(.leading)
                .padding(.bottom)
                .toolbar(.hidden)

                
                ScrollView( showsIndicators: false ) {
                    
                    NavigationLink  {
                        
                    } label: {
                        VStack(spacing : 0) {
                            
                            VStack(alignment : .leading) {
                                
                                HStack {
                                    ProfilePhotoOrInitials(profilePhoto: currentUser.user.profilePhoto, fullName: currentUser.user.name, radius: 40, fontSize: 24)

                                    VStack(alignment : .leading) {
                                        
                                        if currentUser.user.name == "" {
                                            Text("Guest")
                                                .font(.custom("Day Roman", size: 24))
                                                .padding(.leading, 5)
                                        } else {
                                            Text(currentUser.user.name)
                                                .font(.system(size: 18, weight: .bold))
                                                .padding(.leading, 5)
                                        }
                                    }
                                    .font(.custom("Day Roman", size: 24))

                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 18, weight: .regular))
                                        .padding(.trailing, 5)

                                }
                                .foregroundStyle(.black.opacity(0.7))
                                
                                if !currentUser.user.email.isEmpty {
                                    Text(verbatim : "\(currentUser.user.email)")
                                        .font(.custom("Day Roman", size: 14))
                                        .foregroundColor(.primary.opacity(0.7))
                                        .padding(.leading, 5)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical)

                        }
                        .background(.regularMaterial)
                        .cornerRadius(25)
                        .padding()
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Tokens Remaining")
                                .font(.custom("Day Roman", size: 18))
                                .padding(.leading, 5)
                            
                            Spacer()
                            
                            let tokensRemaining = Int(currentUser.user.availableTokens / 100)
                            Text(storeManager.isSubscribed ? "∞" : "\(tokensRemaining)")
                                .font(.custom("Day Roman", size: 24))
                                .padding(.leading, 5)

                        }
                        .padding(.trailing)
                        
                        if storeManager.isSubscribed {
                            VStack(alignment : .leading) {
                                if let plan = storeManager.currentSubscriptionPlan {
                                    let planStr = plan == "monthly_unlimited" ? "Monthly" : "Yearly"
                                    Text("Current Plan: \(planStr)")
                                } else {
                                    Text("Current Plan: Unlimited")
                                }
                                
                                if let expiration = storeManager.subscriptionExpirationDate {
                                    Text("Renews: \(formatDate(expiration))")
                                        .font(.custom("Day Roman", size: 14))
                                        .foregroundStyle(.black.opacity(0.7))
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .font(.custom("Day Roman", size: 18))
                            .background(.regularMaterial)
                            .cornerRadius(25)
                            
                        } else {
                            NavigationLink {
                                SubscriptionView()
                            } label: {
                                Text("Get Unlimited")
                                    .font(.custom("Day Roman", size: 14))
                                    .frame(height : 44)
                                    .frame(maxWidth : .infinity)
                                    .background(.blue)
                                    .foregroundStyle(.white)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }

                    }
                    .padding(.horizontal)

                    AppSettingsSection()
                    
                    AccountSettingsSection()

                }
            }
            .background(.regularMaterial)
            .frame(width : 300)
        }
        
    }
}





struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}



struct MoreSettingsSection : View {
    @EnvironmentObject var currentUser : CurrentUserViewModel
    @State private var isDarkMode = AppManager.shared.isDarkMode

    let shareURL = "https://apps.apple.com/us/app/tutortree/id1353273906"
    @State private var showShareSheet = false

    var body: some View {
        HStack {
            Text("More")
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(Color("text-bold"))
            .padding(.leading, 5)
            
            Spacer()
        }
        .padding(.leading)
        .padding(.top)
        
        VStack(spacing : 0) {
            
            VStack {
                
                NavigationLink {
                    TOSView()
                } label: {
                    AccountItemNavigationView(baseColor: .green, icon: "book.pages.fill", title: "Terms of Service")
                }

                
                AccountItemView(baseColor: .purple, icon: "moon", title: "Dark Mode", isOn: $isDarkMode)
                    .onChange(of: isDarkMode) { _, value in
                        AppManager.shared.toggleTheme()
                        isDarkMode = AppManager.shared.isDarkMode
                    }

                Button(action: {
                    self.showShareSheet = true
                }, label: {
                    AccountItemNavigationView(baseColor: .blue, icon: "arrowshape.turn.up.right.fill", title: "Share")
                })
                .sheet(isPresented: $showShareSheet) {
                    ShareSheet(activityItems: [URL(string: self.shareURL)!])
                }
                
            }
            .padding(.horizontal)
            .padding(.top)

        }
        .background(Color("background-element"))
        .cornerRadius(25)
        .padding(.horizontal)
    }
}


struct AccountSettingsSection : View {
    @EnvironmentObject var currentUser : CurrentUserViewModel

    @State var showLogoutAlert  = false
    
    
    var body: some View {
        HStack {
            Text("Settings")
                .font(.custom("Day Roman", size: 18))
                .padding(.leading, 5)
            
            Spacer()
        }
        .padding(.leading)
        .padding(.top)
        
        VStack(spacing : 0) {
            
            VStack {
                
                Button(action: {
                    showLogoutAlert = true
                }, label: {
                    AccountItemNavigationView(baseColor: .orange, icon: "arrow.counterclockwise", title: "Sign Out")
                })
                .alert(isPresented: $showLogoutAlert) {
                    Alert(
                        title: Text("Are you sure you'd like to log out?"),
                        primaryButton: .destructive(Text("Log Out")) {
                            currentUser.signOut()
                        },
                        secondaryButton: .cancel()
                    )
                }
                
                NavigationLink {
                    DeleteAccountView()
                } label: {
                    AccountItemNavigationView(baseColor: .red, icon: "trash.fill", title: "Delete Account")

                }
                
            }
            .padding(.horizontal)
            .padding(.top)

        }
        .background(.regularMaterial)
        .cornerRadius(25)
        .padding(.horizontal)
    }
}

struct AppSettingsSection : View {
    @EnvironmentObject var currentUser : CurrentUserViewModel
    @State private var showingShareSheet = false

    let shareContent = "Check out WWTD!"

    var body: some View {
        HStack {
            Text("More")
                .font(.custom("Day Roman", size: 18))
                .padding(.leading, 5)
            
            Spacer()
        }
        .padding(.leading)
        .padding(.top)
        
        VStack(spacing : 0) {
            VStack {
                Button(action: {
                    self.showingShareSheet = true
                }, label: {
                    AccountItemNavigationView(baseColor: .blue, icon: "arrowshape.turn.up.forward.fill", title: "Share WWTD")
                })
                .sheet(isPresented: $showingShareSheet) {
                    ShareSheet(activityItems: [shareContent])
                }

                Button(action: {
                    SKStoreReviewController.requestReview()

                }, label: {
                    AccountItemNavigationView(baseColor: .green, icon: "star.fill", title: "Rate the App")

                })
                
            }
            .padding(.horizontal)
            .padding(.top)

        }
        .background(.regularMaterial)
        .cornerRadius(25)
        .padding(.horizontal)
    }
}



#Preview {
    VStack {
        AccountView(showAccountView: .constant(false) )
            .environmentObject(CurrentUserViewModel())
    }
    .background(Color("background"))

}
