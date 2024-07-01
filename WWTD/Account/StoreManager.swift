//
//  StoreManager.swift
//  WWTD
//
//  Created by Adrian Martushev on 6/29/24.
//
import StoreKit
import Combine
import Firebase
import FirebaseAuth

class StoreManager: NSObject, ObservableObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    var subscriptionIDs = ["monthly_unlimited", "yearly_unlimited"]
    var products: [SKProduct] = []
    @Published var productPrice: String? = nil
    @Published var transactionState: SKPaymentTransactionState?
    @Published var transactionError: String?
    @Published var isSubscribed: Bool = false
    @Published var subscriptionExpirationDate: Date? = nil
    @Published var currentSubscriptionPlan: String? = nil

    var onTransactionComplete: ((Bool, String?) -> Void)?

    override init() {
        super.init()
        print("StoreManager initialized.")
        SKPaymentQueue.default().add(self)
        fetchProducts()
        restorePurchases()
        fetchReceipt()
    }
    
    func fetchProducts() {
        print("Fetching products...")
        let request = SKProductsRequest(productIdentifiers: Set(subscriptionIDs))
        request.delegate = self
        request.start()
    }
    
    func restorePurchases() {
        print("Restoring purchases...")
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    private func formatPrice(product: SKProduct) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        return formatter.string(from: product.price) ?? ""
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            self.products = response.products
            if let product = self.products.first {
                self.productPrice = self.formatPrice(product: product)
            } else {
                print("No products found or product not matched.")
            }
            
            // Check for invalid product identifiers
            if !response.invalidProductIdentifiers.isEmpty {
                print("Invalid product identifiers found:")
                for invalidIdentifier in response.invalidProductIdentifiers {
                    print(invalidIdentifier)
                }
            }
        }
    }
    
    func startSubscriptionProcess(for productIdentifier: String, completion: @escaping (Bool, String?) -> Void) {
        guard let product = products.first(where: { $0.productIdentifier == productIdentifier }) else {
            print("Product is nil, cannot initiate payment.")
            completion(false, "Product not available.")
            return
        }

        // Closure to capture the state changes
        self.onTransactionComplete = completion

        buyProduct(product)
    }
    
    func buyProduct(_ product: SKProduct) {
        guard SKPaymentQueue.canMakePayments() else {
            print("Cannot make payments")
            return
        }
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
        print("Added payment for product: \(product.productIdentifier) to the payment queue.")
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            DispatchQueue.main.async {  // Make sure to perform UI updates on the main thread
                self.transactionState = transaction.transactionState
                switch transaction.transactionState {
                case .purchased, .restored:
                    SKPaymentQueue.default().finishTransaction(transaction)
                    self.isSubscribed = true
                    self.updateSubscriptionStatus(isSubscribed: true)
                    DispatchQueue.main.async {
                        self.transactionState = .purchased
                        self.onTransactionComplete?(true, nil) // Call the completion handler on success
                    }
                    
                case .failed:
                    SKPaymentQueue.default().finishTransaction(transaction)
                    if let error = transaction.error as? SKError {
                        DispatchQueue.main.async {
                            self.transactionError = error.localizedDescription
                            self.transactionState = .failed
                            self.onTransactionComplete?(false, error.localizedDescription) // Call the completion handler on failure
                        }
                    }
                default:
                    break
                }
            }
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        // Called when all transactions have been restored
        print("Restore completed transactions finished.")
        if queue.transactions.isEmpty {
            self.updateSubscriptionStatus(isSubscribed: false)
        } else {
            self.updateSubscriptionStatus(isSubscribed: true)
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        print("Restore transactions failed with error: \(error.localizedDescription)")
    }
    
    
    func fetchReceipt() {
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              FileManager.default.fileExists(atPath: receiptURL.path) else {
            print("No receipt found.")
            return
        }
        
        do {
            let receiptData = try Data(contentsOf: receiptURL)
            let receiptString = receiptData.base64EncodedString(options: [])
            validateReceipt(receiptString)
        } catch {
            print("Failed to read receipt data: \(error)")
        }
    }
        
    func validateReceipt(_ receiptString: String) {
        let requestURL = URL(string: "https://sandbox.itunes.apple.com/verifyReceipt")!
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        let requestBody = ["receipt-data": receiptString, "password": "a1d431d87f5c4c878f17917e4a6cba66"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Receipt validation failed: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let receipt = json["latest_receipt_info"] as? [[String: Any]] {
                    self.parseReceipt(receipt)
                } else {
                    print("Invalid receipt data.")
                }
            } catch {
                print("Failed to parse receipt data: \(error)")
            }
        }
        
        task.resume()
    }
        
    func parseReceipt(_ receipt: [[String: Any]]) {
        for entry in receipt {
            if let productID = entry["product_id"] as? String, subscriptionIDs.contains(productID), let expiresDateMs = entry["expires_date_ms"] as? String {
                let expiresDate = Date(timeIntervalSince1970: Double(expiresDateMs)! / 1000.0)
                if expiresDate > Date() {
                    DispatchQueue.main.async {
                        self.updateSubscriptionStatus(isSubscribed: true, expiresDate: expiresDate, productID: productID)
                    }
                    
                    break
                }
            }
        }
    }

    private func updateSubscriptionStatus(isSubscribed: Bool, expiresDate: Date? = nil, productID: String? = nil) {
        if self.isSubscribed != isSubscribed || self.subscriptionExpirationDate != expiresDate || self.currentSubscriptionPlan != productID {
            self.isSubscribed = isSubscribed
            self.subscriptionExpirationDate = expiresDate
            self.currentSubscriptionPlan = productID
            self.updateFirestoreSubscriptionStatus(by: isSubscribed)
        }
    }
    
    func updateFirestoreSubscriptionStatus(by isSubscribed: Bool) {
        let db = Firestore.firestore()
        let userID = AppManager.shared.currentUserID
        
        guard !userID.isEmpty else {
            return
        }
        
        let userRef = db.collection("users").document(userID)
        
        userRef.getDocument { document, error in
            if let document = document, document.exists {
                userRef.updateData(["isSubscribed": isSubscribed]) { error in
                    if let error = error {
                        print("Error updating subscription status for user \(error.localizedDescription)")
                    } else {
                        print("Updated subscription status for user to \(isSubscribed)")
                    }
                }
            } else {
                print("Document does not exist: \(error?.localizedDescription ?? "")")
            }
        }
    }

}

