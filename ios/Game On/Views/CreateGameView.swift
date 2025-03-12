//
//  CreateGameView.swift
//  Game On!
//
//  Created by Fynn Herr on 27/01/2025.
//

import SwiftUI

struct CreateGameView: View {
    @EnvironmentObject var connectionManager: MPConnectionManager
    @EnvironmentObject var game: GameService
    @AppStorage("yourName") var yourName = "Fynn"

    @State private var newPlayers: [String] = []
    @State private var startGame: Bool = false
    @State private var navigateToLobby: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgCol.edgesIgnoringSafeArea(.all) // Background color
                
                VStack {
                    // Header
                    Text("\(connectionManager.myPeerId.displayName)'s Lobby")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // Scrollable List for Players
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            // Leader
                            playerRow(name: connectionManager.myPeerId.displayName, role: "Leader")
                            
                            // Joined Players
                            ForEach(newPlayers, id: \.self) { player in
                                playerRow(name: player, role: "Member")
                            }
                        }
                        .padding(.horizontal)
                    }
                    .scrollContentBackground(.hidden)
                    
                    Spacer()
                    
                    // Start Game Button
                    HStack {
                        Spacer()
                        Button("Start Game") {
                            // Start game action
                        }
                        .padding()
                        .background(Color.button, in: RoundedRectangle(cornerRadius: 10))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    }
                    .padding()
                }
            }
            .colorScheme(.dark) // Dark mode
            .onAppear {
                connectionManager.startAdvertising()
                print("Start advertising...")
            }
            .onDisappear {
                connectionManager.stopAdvertising()
                connectionManager.resetConnectionState()
                print("Stop advertising...")
            }
            .onChange(of: connectionManager.paired) { paired in
                if paired {
                    navigateToLobby = true
                    //print("Connection established, navigating to LobbyView")
                }
            }
            /*.navigationDestination(isPresented: $navigateToLobby) {
                //LobbyView()
                CreateGameView()
            }*/
            .alert("Join Request", isPresented: $connectionManager.receivedInvite) {
                if let receivedPeer = connectionManager.receivedInviteFrom {
                    Button("Accept") {
                        newPlayers.append(receivedPeer.displayName)
                        connectionManager.invitationHandler?(true, connectionManager.session)
                    }
                    Button("Reject") {
                        connectionManager.invitationHandler?(false, nil)
                    }
                }
            } message: {
                Text("\(connectionManager.receivedInviteFrom?.displayName ?? "Unknown") wants to join your game.")
            }
        }
    }

    private func playerRow(name: String, role: String) -> some View {
        HStack {
            Text(name)
                .foregroundColor(.white)
            Spacer()
            Text(role)
                .foregroundColor(role == "Leader" ? .green : .blue)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}

#Preview {
    CreateGameView()
        .environmentObject(MPConnectionManager(yourName: "Sample"))
        .environmentObject(GameService())
}
