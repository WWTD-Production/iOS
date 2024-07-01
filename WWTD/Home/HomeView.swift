//
//  HomeView.swift
//  WWTD
//
//  Created by Adrian Martushev on 6/29/24.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var openAIVM : OpenAIViewModel
    @EnvironmentObject var currentUser : CurrentUserViewModel

    @State var showAccountView = false
    @State var showHistoryView = false
    @State var showSubscriptionView = false
    
    let presets = [
        "How can I strengthen my faith?",
        "How can I overcome temptation?",
        "What is God's purpose for my life?",
        "How can I find peace in difficult times?",
        "What does the Bible say about forgiveness?",
        "What should I do when I feel lost or unsure?",
        "How can I serve others in my community?",
        "What does it mean to live a Christ-centered life?",
        "How should I handle conflict with others?",
        "How can I improve my prayer life?",
        "What does it mean to love your neighbor?",
        "How can I grow spiritually?",
        "What is the significance of baptism?",
        "How can I trust God more fully?",
        "What does it mean to live by faith and not by sight?",
        "How can I find comfort in times of grief?",
        "What does the Bible say about marriage and family?",
        "How can I share my faith with others?",
        "What is the importance of regular worship?"
    ]
    
    var body: some View {
        
        ZStack {
            VStack {
                
                ZStack {
                    HStack {
                        Button(action: {
                            showHistoryView = true
                        }, label: {
                            Image(systemName: "line.3.horizontal")
                                .foregroundStyle(.black.opacity(0.7))
                        })
                        
                        Spacer()
                        
                        Button(action: {
                            showAccountView.toggle()
                        }, label: {
                            Image(systemName: "gear")
                                .foregroundStyle(.black.opacity(0.7))
                        })

                    }
                    .padding()
                    
                    Text("WWTD?")
                        .font(.custom("Day Roman", size: 14))

                }

                if openAIVM.messages.isEmpty {
                    VStack {
                        Spacer()
                        
                        Image("Logo Only")
                            .resizable()
                            .scaledToFit()
                            .frame(width : 60, height : 60)
                        
                        Spacer()
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(presets, id : \.self) { preset in
                                    Button(action: {
                                        if currentUser.user.availableTokens > 0 || currentUser.user.isSubscribed {
                                            openAIVM.query = preset
                                            Task {
                                                await openAIVM.sendQuery(playAudio: false)
                                            }
                                        } else {
                                            showSubscriptionView = true
                                        }
                                    }, label: {
                                        Text(preset)
                                            .foregroundStyle(.black.opacity(0.7))
                                            .font(.custom("Day Roman", size: 14))
                                            .frame(height : 44)
                                            .padding(.horizontal, 12)
                                            .background(.white)
                                            .cornerRadius(10)
                                    })

                                }
                            }
                            .padding(.leading)
                        }
                        .padding(.bottom)
                    }
                    
                } else {
                    ScrollViewReader { scrollViewProxy in
                        ScrollView {
                            ForEach(openAIVM.messages, id: \.id) { message in
                                HStack(alignment : .top) {
                                    if message.role == .user {
                                        Spacer()
                                        Text("\(message.content)")
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color("logo-background"))
                                            .cornerRadius(10)
                                            .foregroundColor(.black.opacity(0.7))
                                            .frame(maxWidth: 300, alignment: .trailing)
                                            .font(.custom("Day Roman", size: 14))
                                    } else {
                                        Image("Logo Only")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width : 25, height : 25)
                                        
                                        Text("\(message.content)")
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color.black.opacity(0.7))
                                            .cornerRadius(10)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: 300, alignment: .leading)
                                            .font(.custom("Day Roman", size: 14))

                                        Spacer()
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                                .id(message.id)

                            }
                        }
                        .onChange(of: openAIVM.messages) { _, _ in
                            if let lastId = openAIVM.messages.last?.id {
                                withAnimation {
                                    scrollViewProxy.scrollTo(lastId, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex : "#fefefe")
                                .shadow(.inner(color: .white.opacity(0.1), radius: 2, x: -1, y: -1))
                                .shadow(.inner(color: .black.opacity(0.3), radius: 2, x: 2, y: 2))
                            )
                            .frame(height : 50)
                        
                        TextField("What Would They Do?", text: $openAIVM.query)
                            .foregroundColor(.black.opacity(0.5))
                            .font(.custom("Day Roman", size: 14))
                            .padding()
                            .onSubmit {
                                if !openAIVM.query.isEmpty {
                                    if currentUser.user.availableTokens > 0 || currentUser.user.isSubscribed {
                                        Task {
                                            await openAIVM.sendQuery(playAudio: false)
                                        }
                                    } else {
                                        showSubscriptionView = true
                                    }

                                }
                            }
                            .padding(.trailing, 30)

                        HStack {
                            Spacer()
                            Button {
                                if !openAIVM.query.isEmpty {
                                    if currentUser.user.availableTokens > 0 || currentUser.user.isSubscribed {
                                        Task {
                                            await openAIVM.sendQuery(playAudio: false)
                                        }
                                    } else {
                                        showSubscriptionView = true
                                    }
                                }
                            } label: {
                                Image(systemName : "arrow.up.circle.fill")
                                    .font(Font.custom("SF Pro", size: 22))
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(openAIVM.query.isEmpty ? .gray.opacity(0.5) : .blue)
                            }
                            .disabled(openAIVM.query.isEmpty)
                            .sheet(isPresented: $showSubscriptionView, content: {
                                SubscriptionView()
                            })

                        }
                        .padding(.trailing)

                    }
                }
                .padding(.bottom)
                .padding(.horizontal)
            }
            .background(.regularMaterial)
            .onTapGesture {
                hideKeyboard()
            }
            .overlay {
                Color(showHistoryView || showAccountView ? .black.opacity(0.3) : .clear)
                    .onTapGesture {
                        showHistoryView = false
                        showAccountView = false
                    }
                    .edgesIgnoringSafeArea(.all)
            }
            
            HistoryView(showHistory: $showHistoryView)
                .leadingEdgeSheet(isPresented: showHistoryView)
                        
            AccountView(showAccountView : $showAccountView)
                .trailingEdgeSheet(isPresented: showAccountView)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(OpenAIViewModel())
        .environmentObject(CurrentUserViewModel())
        .environmentObject(StoreManager())

}

