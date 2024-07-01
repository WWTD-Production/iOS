//
//  AppleAuthentication.swift
//  WWTD
//
//  Created by Adrian Martushev on 6/27/24.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth
import CryptoKit
import Firebase


extension CurrentUserViewModel {
    
    func randomNonceString(length: Int = 32) -> String {
      precondition(length > 0)
      var randomBytes = [UInt8](repeating: 0, count: length)
      let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
      if errorCode != errSecSuccess {
        fatalError(
          "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
        )
      }

      let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

      let nonce = randomBytes.map { byte in
        // Pick a random character from the set, wrapping around if needed.
        charset[Int(byte) % charset.count]
      }

      return String(nonce)
    }
    
    @available(iOS 13, *)
    func sha256(_ input: String) -> String {
      let inputData = Data(input.utf8)
      let hashedData = SHA256.hash(data: inputData)
      let hashString = hashedData.compactMap {
        String(format: "%02x", $0)
      }.joined()

      return hashString
    }
    
    
    func startSignInWithAppleFlow(completion: @escaping (Bool, Error?) -> Void) {
      let nonce = randomNonceString()
      currentNonce = nonce
      let appleIDProvider = ASAuthorizationAppleIDProvider()
      let request = appleIDProvider.createRequest()
      request.requestedScopes = [.fullName, .email]
      request.nonce = sha256(nonce)

      let authorizationController = ASAuthorizationController(authorizationRequests: [request])
      authorizationController.delegate = self
      authorizationController.presentationContextProvider = self
      authorizationController.performRequests()
        
      self.appleSignInCompletionHandler = completion

    }
}


@available(iOS 13.0, *)
extension CurrentUserViewModel: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Return the window of the current SwiftUI view
        return UIApplication.shared.windows.first { $0.isKeyWindow }!
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                self.appleSignInCompletionHandler?(false, NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token"]))
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                self.appleSignInCompletionHandler?(false, NSError(domain: "AuthError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unable to serialize token string"]))
                return
            }
            // Initialize a Firebase credential, including the user's full name.
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                              rawNonce: nonce,
                                                              fullName: appleIDCredential.fullName)
            // Sign in with Firebase.
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase sign in with Apple errored: \(error)")
                    self.appleSignInCompletionHandler?(false, error)
                } else if let user = authResult?.user {
                    // Successfully authenticated with Firebase. Now fetch or create user profile.
                    let usersRef = Firestore.firestore().collection("users").document(user.uid)
                    
                    usersRef.getDocument { (document, error) in
                        if let document = document, document.exists {
                            print("User already exists in Firestore.")
                        } else {
                            // Create a new user document in Firestore
                            let newUser = [
                                "id" : self.currentUserID,
                                "name":  appleIDCredential.fullName?.formatted() ?? "",
                                "email": appleIDCredential.email ?? "",
                                "profilePhoto": ""
                            ]
                            usersRef.setData(newUser) { error in
                                self.appleSignInCompletionHandler?(true, nil)

                            }
                        }
                    }
                    
                    self.appleSignInCompletionHandler?(true, nil)

                }
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Sign in with Apple errored: \(error)")
        self.appleSignInCompletionHandler?(false, error)
    }

}
