//
//  OpenAIViewModel.swift
//  WWTD
//
//  Created by Adrian Martushev on 6/27/24.
//

import SwiftUI
import Speech
import AVFoundation
import OpenAI
import FirebaseFirestore


struct MessageThread: Identifiable {
    var id: String
    var dateCreated: Date
    var previewMessage: String
    var model: String
    var status : String
}



struct ChatMessage: Identifiable, Equatable {
    var id: UUID = UUID()
    var role: Role
    var content: String
    var timestamp: Date = Date()

    enum Role: String {
        case user = "user"
        case assistant = "assistant"
    }
}

enum Voice: String, CaseIterable, Identifiable {
    case alloy = "alloy"
    case echo = "echo"
    case fable = "fable"
    case onyx = "onyx"
    case nova = "nova"
    case shimmer = "shimmer"

    var id: String { self.rawValue }

    // Convert to API's voice type
    func toAPIVoice() -> AudioSpeechQuery.AudioSpeechVoice {
        return AudioSpeechQuery.AudioSpeechVoice(rawValue: self.rawValue) ?? .alloy
    }
}


struct VoiceOption: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String
}

struct LanguageOptions: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String
}

extension UserDefaults {
    static let selectedVoiceKey = "selectedVoice"
    static let selectedLanguageKey = "selectedLanguage"
}

class OpenAIViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    let openAI = OpenAI(apiToken: "")
    @Published var query = ""
    @Published var messages: [ChatMessage] = []
    @Published var voices = Voice.allCases
    @Published var languages = [
        LanguageOptions(name: "German"),
        LanguageOptions(name: "English")
    ]
    
    @Published var selectedVoice: Voice {
        didSet {
            saveVoiceSelection()
        }
    }
    @Published var selectedLanguage: LanguageOptions {
        didSet {
            saveLanguageSelection()
        }
    }
    
    var audioPlayer: AVAudioPlayer?
    @Published var isAudioPlaying: Bool = false
    @Published var isResponding = false
    @Published var responsePending = false
    @Published var presetInstructionsAvailable = false
    @Published var currentThreadID: String?

    override init() {
        selectedVoice = UserDefaults.standard.string(forKey: UserDefaults.selectedVoiceKey)
            .flatMap { Voice(rawValue: $0) } ?? .alloy
        selectedLanguage = UserDefaults.standard.string(forKey: UserDefaults.selectedLanguageKey)
            .flatMap { LanguageOptions(name: $0) } ?? LanguageOptions(name: "English")
        super.init()
    }

    private func saveVoiceSelection() {
        UserDefaults.standard.set(selectedVoice.rawValue, forKey: UserDefaults.selectedVoiceKey)
    }

    private func saveLanguageSelection() {
        UserDefaults.standard.set(selectedLanguage.name, forKey: UserDefaults.selectedLanguageKey)
    }
    
    
    func startNewConversation(previewMessage: String, model: String, completion: @escaping (Result<Void, Error>) -> Void) {
        createMessageThread(previewMessage: previewMessage, model: model) { result in
            switch result {
            case .success(let threadID):
                self.currentThreadID = threadID
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
    func sendQuery(playAudio : Bool) async {
        print("Sending query : \(query)")
        responsePending = true
        let userMessage = ChatMessage(role: .user, content: query)
        
        DispatchQueue.main.async {
            self.messages.append(userMessage)
            if let threadID = self.currentThreadID {
                self.saveMessageToFirestore(messageThreadID: threadID, message: userMessage) { result in
                    switch result {
                    case .success:
                        print("User message saved successfully.")
                    case .failure(let error):
                        print("Failed to save user message: \(error)")
                    }
                }
            } else {
                // If no current thread, create a new one
                let previewMessage = self.query.prefix(100) + "..."
                self.startNewConversation(previewMessage: String(previewMessage), model: "gpt-4o-2024-05-13") { result in
                    switch result {
                    case .success:
                        if let threadID = self.currentThreadID {
                            self.saveMessageToFirestore(messageThreadID: threadID, message: userMessage) { result in
                                switch result {
                                case .success:
                                    print("User message saved successfully.")
                                case .failure(let error):
                                    print("Failed to save user message: \(error)")
                                }
                            }
                        }
                    case .failure(let error):
                        print("Failed to create message thread: \(error)")
                    }
                }
            }
        }
        
        var systemMessage : ChatQuery.ChatCompletionMessageParam = .init(role: .assistant, content: "You are a christian assistant providing helpful advice for users based on the teachings of Jesus Christ. Quote scripture whenever applicable and provide concise answers.")!

        let chatQuery = ChatQuery(
            messages: [systemMessage, .init(role: .user, content: query)!],
            model: .gpt4_o
        )
        
        DispatchQueue.main.async {
            self.query = ""
        }
        
        do {
            // Execute the query
            let result = try await openAI.chats(query: chatQuery)
            DispatchQueue.main.async {
                if let firstChoice = result.choices.first,
                   case let .string(responseContent) = firstChoice.message.content {
                    let assistantMessage = ChatMessage(role: .assistant, content: responseContent)
                    self.messages.append(assistantMessage)
                    self.responsePending = false
                    self.query = ""

                    // Save assistant message to Firestore
                    if let threadID = self.currentThreadID {
                        self.saveMessageToFirestore(messageThreadID: threadID, message: assistantMessage) { result in
                            switch result {
                            case .success:
                                print("Assistant message saved successfully.")
                            case .failure(let error):
                                print("Failed to save assistant message: \(error)")
                            }
                        }
                    }

                    // Print token usage and update Firestore
                    if let usage = result.usage {
                        self.updateTokens(by: usage.totalTokens) { result in
                            switch result {
                            case .success:
                                print("User tokens updated successfully.")
                            case .failure(let error):
                                print("Failed to update user tokens: \(error)")
                            }
                        }
                    }

                } else {
                    print("Received content is not a string or is empty")
                }
            }
        } catch {
            print("Failed to get response from OpenAI: \(error.localizedDescription)")
            self.responsePending = false

        }
    }
    
    private func createMessageThread(previewMessage: String, model: String, completion: @escaping (Result<String, Error>) -> Void) {
        let userID = AppManager.shared.currentUserID
        
        guard !userID.isEmpty else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID is empty."])))
            return
        }
        let messageThreadRef = database.collection("users").document(userID).collection("messageThreads").document()
        
        let messageThreadData: [String: Any] = [
            "id": messageThreadRef.documentID,
            "dateCreated": Timestamp(),
            "previewMessage": previewMessage,
            "model": model,
            "status" : "active"
        ]
        
        messageThreadRef.setData(messageThreadData) { error in
            if let error = error {
                print("Error creating message thread: \(error)")
                completion(.failure(error))
            } else {
                print("Message thread successfully created.")
                completion(.success(messageThreadRef.documentID))
            }
        }
    }
    
    private func saveMessageToFirestore(messageThreadID: String, message: ChatMessage, completion: @escaping (Result<Void, Error>) -> Void) {
        let userID = AppManager.shared.currentUserID
        
        guard !userID.isEmpty else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID is empty."])))
            return
        }
        let userMessagesRef = database.collection("users").document(userID).collection("messageThreads").document(messageThreadID).collection("messages")
        let messageData: [String: Any] = [
            "id": message.id.uuidString,
            "role": message.role.rawValue,
            "content": message.content,
            "timestamp": Timestamp(date: message.timestamp)
        ]
        
        userMessagesRef.addDocument(data: messageData) { error in
            if let error = error {
                print("Error saving message: \(error)")
                completion(.failure(error))
            } else {
                print("Message successfully saved.")
                completion(.success(()))
            }
        }
    }
    
    func updateTokens(by amount: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        let userID = AppManager.shared.currentUserID
        
        guard !userID.isEmpty else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID is empty."])))
            return
        }
        
        let userRef = database.collection("users").document(userID)
        
        userRef.getDocument { document, error in
            if let document = document, document.exists {
                if var currentTokens = document.data()?["availableTokens"] as? Int {
                    currentTokens -= amount
                    if currentTokens < 0 {
                        currentTokens = 0
                    }
                    userRef.updateData(["availableTokens": currentTokens]) { error in
                        if let error = error {
                            print("Error updating tokens: \(error)")
                            completion(.failure(error))
                        } else {
                            print("Tokens successfully updated.")
                            completion(.success(()))
                        }
                    }
                } else {
                    print("Document does not contain 'availableTokens' field. Initializing it.")
                    let initialTokens = max(10000 - amount, 0)
                    userRef.setData(["availableTokens": initialTokens], merge: true) { error in
                        if let error = error {
                            print("Error initializing tokens: \(error)")
                            completion(.failure(error))
                        } else {
                            print("Tokens successfully initialized.")
                            completion(.success(()))
                        }
                    }
                }
            } else {
                print("Document does not exist: \(error?.localizedDescription ?? "")")
                completion(.failure(error ?? NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Document does not exist."])))
            }
        }
    }
    
    
    func fetchMessages(for thread: MessageThread) {
        let userID = AppManager.shared.currentUserID
        
        guard !userID.isEmpty else {
            return
        }
        currentThreadID = thread.id
        
        let db = Firestore.firestore()
        let messagesRef = db.collection("users").document(userID).collection("messageThreads").document(thread.id).collection("messages")

        messagesRef.order(by: "timestamp", descending: false).getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("No messages found or an error occurred: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            self.messages = documents.compactMap { doc -> ChatMessage? in
                let data = doc.data()
                guard let role = data["role"] as? String,
                      let content = data["content"] as? String,
                      let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() else {
                    return nil
                }
                return ChatMessage(id: UUID(uuidString: doc.documentID) ?? UUID(), role: ChatMessage.Role(rawValue: role) ?? .user, content: content, timestamp: timestamp)
            }
        }
    }
    

    
    
    func synthesizeResponse(from text: String) async {
        let speechQuery = AudioSpeechQuery(
            model: .tts_1,
            input: text,
            voice: selectedVoice.toAPIVoice(),
            responseFormat: .mp3,
            speed: 1.0
        )
        do {
            let speechResult = try await openAI.audioCreateSpeech(query: speechQuery)
            DispatchQueue.main.async {
                self.playAudio(from: speechResult.audio)
            }
        } catch {
            DispatchQueue.main.async {
                print("Error synthesizing speech: \(error)")
            }
        }
    }
    
    /// Prepares and manages the audio session for playback
    func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    /// Plays audio from given data.
    func playAudio(from data: Data) {
        setupAudioSession()
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self // Set delegate to self to detect when audio finishes playing
            audioPlayer?.play()
            DispatchQueue.main.async {
                self.responsePending = false
                self.isResponding = true
                self.isAudioPlaying = true
            }
        } catch {
            print("Failed to play audio: \(error)")
            DispatchQueue.main.async {
                self.isResponding = false
                self.isAudioPlaying = false
            }
        }
    }

    /// Called when audio playback finishes
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isResponding = false
            self.isAudioPlaying = false

        }
    }
    
    func stopAudio() {
        if audioPlayer?.isPlaying ?? false {
            audioPlayer?.stop()
            audioPlayer?.currentTime = 0
            self.isResponding = false
        }
    }
}
