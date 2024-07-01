//
//  CurrentUserViewModel.swift
//  WWTD
//
//  Created by Adrian Martushev on 6/27/24.
//

import SwiftUI
import Foundation
import Combine
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage


struct User : Identifiable {
    var id : String
    var email : String
    var name : String
    var profilePhoto : String
    var availableTokens : Int
    var isSubscribed : Bool
    
    enum CodingKeys: String, CodingKey {
        case id = "objectID"
        // Map other properties as usual
        case email, name, profilePhoto, availableTokens, isSubscribed
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "email" : email,
            "name" : name,
            "profilePhoto" : profilePhoto,
            "isSubscribed" : isSubscribed
        ]
    }
}

let empty_user = User(id: "", email : "", name :  "", profilePhoto : "", availableTokens : 0, isSubscribed : false)

class CurrentUserViewModel : NSObject, ObservableObject {
    let delegate = UIApplication.shared.delegate as! AppDelegate

    @Published var refreshID = UUID()
    
    //Authentication
    var currentNonce: String?
    @Published var shouldDeleteAccount = false
    var appleSignInCompletionHandler: ((Bool, Error?) -> Void)?

    @Published var user : User = empty_user


    //Handles real-time authentication changes to conditionally display login/home views
    var didChange = PassthroughSubject<CurrentUserViewModel, Never>()
    
    @Published var currentUserID: String = "" {
        didSet {
            didChange.send(self)
        }
    }
    
    @Published var messageThreads: [MessageThread] = []

    override init() {
        super.init()
        fetchMessageThreads()
    }
    
    var handle: AuthStateDidChangeListenerHandle?

    func listen () {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                
                print("User Authenticated: \(user.uid)")
                self.currentUserID = user.uid
                AppManager.shared.currentUserID = self.currentUserID
                self.getUserInfo(userID: user.uid)
                
            } else {
                print("No user available, loading initial view")
                AppManager.shared.currentUserID = ""
                self.currentUserID = ""
            }
        }
    }
    
    //Fetch initial data once, add listeners for appropriate conditions
    func getUserInfo(userID: String) {
        let userInfo = database.collection("users").document(userID)
        
        userInfo.getDocument { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
            }
            
            self.listenForCoreUserChanges(userID: self.currentUserID)
        }
    }
    
    func listenForCoreUserChanges(userID: String) {
        database.collection("users").document(userID).addSnapshotListener { snapshot, error in
            guard let document = snapshot else {
              print("Error fetching document: \(error!)")
              return
            }
            
            let userData = document.data()
            self.user = User(id: self.currentUserID,
                             email: userData?["email"] as? String ?? "",
                             name: userData?["name"] as? String ?? "",
                             profilePhoto: userData?["profilePhoto"] as? String ?? "",
                             availableTokens: userData?["availableTokens"] as? Int ?? 0,
                             isSubscribed: userData?["isSubscribed"] as? Bool ?? false
            )
            
            
        }
    }

    

    func updateProfilePhoto(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.4) else {
            completion(false)
            return
        }
        
        let storageRef = Storage.storage().reference()
        let filePath = "profilePhotos/\(self.user.id).jpg"
        let storagePhotoRef = storageRef.child(filePath)
        
        storagePhotoRef.putData(imageData, metadata: nil) { metadata, error in
            guard metadata != nil else {
                print("Failed to upload photo: \(error?.localizedDescription ?? "unknown error")")
                completion(false)
                return
            }
            
            storagePhotoRef.downloadURL { url, error in
                guard let downloadURL = url else {
                    print("Download URL not found.")
                    completion(false)
                    return
                }
                
                let db = Firestore.firestore()
                db.collection("users").document(self.user.id).updateData(["profilePhoto": downloadURL.absoluteString]) { error in
                    if let error = error {
                        print("Failed to update user document: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        self.user.profilePhoto = downloadURL.absoluteString
                        completion(true)
                    }
                }
            }
        }
    }

    
    func updateUser(data: [String: Any]) {
        if self.currentUserID != "" {
            let userInfo = database.collection("users").document(self.currentUserID)
            userInfo.updateData(data) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("User data successfully updated: \(data)")
                }
            }
        } else {
            print("Attempting to update non existent user with data : \(data)")
        }

    }
    
    func createUserFromEmail(email: String, password: String, completion: @escaping (Bool, String) -> Void) {
        
        //Create auth user
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Error creating auth user: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
            } else if let authResult = authResult {
                                
                // Create a new user
                var newUser = empty_user
                newUser.id = authResult.user.uid
                
                // Convert user to dictionary
                var data = newUser.toDictionary()
                print("Creating new user with data : \(data)")
                
                // Add user to Firestore
                database.collection("users").document(authResult.user.uid).setData(data) { error in
                    if let error = error {
                        // Handle any errors here
                        print("Error writing user to Firestore: \(error.localizedDescription)")
                        completion(false, error.localizedDescription)
                    } else {
                        // Success
                        print("User successfully written to Firestore")
                        completion(true, "")
                    }
                }
            }
        }
    }
    
    func fetchMessageThreads() {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let userThreadsRef = db.collection("users").document(userID).collection("messageThreads")

        userThreadsRef.whereField("status", isEqualTo: "active")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("No documents found or an error occurred: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                var fetchedThreads: [MessageThread] = documents.compactMap { doc -> MessageThread? in
                    let data = doc.data()
                    guard let dateCreated = (data["dateCreated"] as? Timestamp)?.dateValue(),
                          let previewMessage = data["previewMessage"] as? String,
                          let model = data["model"] as? String else {
                        return nil
                    }
                    return MessageThread(id: doc.documentID, dateCreated: dateCreated, previewMessage: previewMessage, model: model, status: "active")
                }

                // Sort the threads by dateCreated in descending order
                fetchedThreads.sort { $0.dateCreated > $1.dateCreated }

                DispatchQueue.main.async {
                    self.messageThreads = fetchedThreads
                }
            }
    }
    
    func createAccount() {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(self.currentUserID)

        // Check if the document exists
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                // Document exists - handle the case where account shouldn't be overwritten or merged
                print("Account already exists. No changes made.")
                // Optionally, handle any user notifications here
            } else {
                // Document does not exist, create a new one
                let data = [
                    "id" : self.currentUserID,
                    "email": self.user.email,
                    "name": self.user.name,
                    "availableTokens" : 100000
                ] as [String: Any]

                userRef.setData(data) { error in
                    if let error = error {
                        print("Error creating user document: \(error)")
                    } else {
                        print("Successfully created user document")
                    }
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            print("Successfully signed out user")
            resetCurrentUserVM()
            AppManager.shared.navigationPath = [.initial]
            
        } catch {
            print("Error signing out user")
        }
    }
    
    
    func resetCurrentUserVM() {
        refreshID = UUID()
            
        currentUserID = ""
        user = empty_user
    }
    

    
}

