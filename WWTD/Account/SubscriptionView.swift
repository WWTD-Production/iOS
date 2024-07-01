//
//  SubscriptionView.swift
//  WWTD
//
//  Created by Adrian Martushev on 6/29/24.
//

import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @State private var selectedSubscription: SubscriptionType = .yearly
    @EnvironmentObject var storeManager : StoreManager
    
    
    enum SubscriptionType {
        case yearly, monthly
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image("Logo Only")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
            
            Text("Unlock Full Access")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Get access to all of our features")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()

            VStack(alignment: .leading, spacing: 15) {
                FeatureRow(text: "Unlimited messages")
                FeatureRow(text: "Daily new content")
                FeatureRow(text: "Share responses")
                FeatureRow(text: "Save your discussions")
            }
            
            Spacer()
            
            VStack(spacing: 20) {
                let yearlyPrice = storeManager.products.first { $0.productIdentifier == "yearly_unlimited" }?.localizedPrice ?? "$9.99"
                Button(action: {
                    selectedSubscription = .yearly

                }, label: {
                    SubscriptionOptionView(
                        title: "Yearly Subscription",
                        description: "Get full access for just \(yearlyPrice)",
                        isSelected: selectedSubscription == .yearly
                    )
                })
                
                let monthlyPrice = storeManager.products.first { $0.productIdentifier == "monthly_unlimited" }?.localizedPrice ?? "$1.99"
                Button(action: {
                    selectedSubscription = .monthly
                }, label: {
                    SubscriptionOptionView(
                        title: "Monthly Subscription",
                        description: "Get full access for just \(monthlyPrice)",
                        isSelected: selectedSubscription == .monthly
                    )
                })

            }
            
            Button(action: {
                // Handle purchase action
                let productIdentifier = selectedSubscription == .yearly ? "yearly_unlimited" : "monthly_unlimited"
                storeManager.startSubscriptionProcess(for: productIdentifier) { success, error in
                    if success {
                        // Handle successful transaction
                        print("Transaction successful!")
                        self.presentationMode.wrappedValue.dismiss()
                    } else {
                        // Handle transaction failure
                        print("Transaction failed: \(error ?? "Unknown error")")
                    }
                }
            }) {
                Text("Purchase")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            Button(action: {
                storeManager.restorePurchases()
            }) {
                Text("Restore Purchases")
                    .foregroundColor(.blue)
                    .font(.system(size: 12))
            }
            
            Spacer()
        }
        .padding()
        .padding(.horizontal)
    }
}

struct SubscriptionOptionView: View {
    let title: String
    let description: String
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing : 5) {
                Text(title)
                    .font(.system(size: 16, weight : .semibold))
                Text(description)
                    .foregroundColor(.black.opacity(0.7))
                    .font(.system(size: 14, weight : .regular))
                    .padding(.top, 2)

            }
            Spacer()
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .gray)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.blue : Color.gray, lineWidth: 1))
    }
}

struct FeatureRow: View {
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.blue)
            Text(text)
                .font(.system(size: 16, weight : .medium))
            Spacer()
        }
    }
}

extension SKProduct {
    var localizedPrice: String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = self.priceLocale
        return formatter.string(from: self.price)
    }
}

#Preview {
    SubscriptionView()
        .environmentObject(StoreManager())
}
