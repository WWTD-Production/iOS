//
//  HistoryView.swift
//  WWTD
//
//  Created by Adrian Martushev on 6/29/24.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var currentUser: CurrentUserViewModel
    @EnvironmentObject var openAIVM: OpenAIViewModel

    @Binding var showHistory: Bool
    
    var body: some View {
        HStack {
            VStack {
                HStack {
                    Text("History")
                        .font(.custom("Day Roman", size: 34))
                        .padding(.leading, 5)
                    
                    Spacer()
                    
                    Button {
                        showHistory = false
                    } label: {
                        Image(systemName: "xmark.circle")
                            .foregroundStyle(.black.opacity(0.8))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
                .toolbar(.hidden)
                
                List {
                    ForEach(groupedMessageThreads.keys.sorted(by: >), id: \.self) { date in
                        Section(header: Text(sectionHeader(for: date))) {
                            ForEach(groupedMessageThreads[date] ?? []) { thread in
                                Button {
                                    openAIVM.fetchMessages(for: thread)
                                    showHistory = false
                                } label: {
                                    Text(thread.previewMessage)
                                        .foregroundStyle(.black.opacity(0.7))
                                }

                            }
                            .onDelete { indexSet in
                                deleteThread(at: indexSet, for: date)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())

            }
            .frame(width: 300)
            .background(Color(hex : "#F2F2F7"))
            Spacer()
        }
    }
    
    private var groupedMessageThreads: [Date: [MessageThread]] {
        Dictionary(grouping: currentUser.messageThreads) { thread in
            Calendar.current.startOfDay(for: thread.dateCreated)
        }
    }

    private func sectionHeader(for date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }

    private func deleteThread(at offsets: IndexSet, for date: Date) {
        let threads = groupedMessageThreads[date] ?? []
        offsets.forEach { index in
            let thread = threads[index]
            currentUser.deleteMessageThread(thread)
            openAIVM.messages = []
            openAIVM.currentThreadID = nil
        }
    }
}

extension CurrentUserViewModel {
    func deleteMessageThread(_ thread: MessageThread) {
        guard !currentUserID.isEmpty else { return }

        let userThreadRef = database.collection("users").document(currentUserID).collection("messageThreads").document(thread.id)

        userThreadRef.updateData(["status": "delete"]) { error in
            if let error = error {
                print("Error updating thread status: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    if let index = self.messageThreads.firstIndex(where: { $0.id == thread.id }) {
                        self.messageThreads[index].status = "delete"
                    }
                    print("Thread status updated to delete successfully.")
                }
            }
        }
    }
}


#Preview {
    HistoryView(showHistory : .constant(false))
        .environmentObject(CurrentUserViewModel())
}
