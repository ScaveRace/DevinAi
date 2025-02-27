# WebRTC Chat Application

A Flutter application that enables real-time chat between multiple users using WebRTC for peer-to-peer communication.

## Features

- **Lobby System**: Create and join chat rooms
- **Peer-to-Peer Connection**: Direct communication between users using WebRTC
- **Real-time Messaging**: Send and receive messages instantly
- **Notifications**: Get notified when new messages arrive
- **Disconnection Handling**: Automatic handling when users leave
- **Cross-Platform**: Works on both iOS and Android

## Setup Instructions

### Prerequisites

- Flutter SDK (version 3.7.0 or higher)
- Dart SDK (version 3.0.0 or higher)
- Android Studio or Xcode for mobile development
- Firebase account for the signaling server

### Firebase Setup

1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add an Android and/or iOS app to your Firebase project
3. Download the configuration files:
   - For Android: `google-services.json` (place in `android/app/`)
   - For iOS: `GoogleService-Info.plist` (place in `ios/Runner/`)
4. Enable Firestore Database in your Firebase project

### Installation

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/webrtc_chat_app.git
   cd webrtc_chat_app
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Run the application:
   ```
   flutter run
   ```

## Usage Guide

### Creating a Lobby

1. Launch the application
2. Enter your name on the login screen
3. Tap "Create Lobby" on the lobby screen
4. Enter a name for your lobby and tap "Create"

### Joining a Lobby

1. Launch the application
2. Enter your name on the login screen
3. Browse the list of available lobbies
4. Tap on a lobby to join it

### Chatting

1. Type your message in the text field at the bottom of the chat screen
2. Tap the send button or press enter to send the message
3. All users in the lobby will receive your message in real-time
4. When you receive a message, a notification will appear if the app is in the background

### Leaving a Lobby

1. Tap the back button or the exit icon in the app bar
2. You will be returned to the lobby screen
3. Other users will be notified that you have left

## Technical Implementation

- **WebRTC**: Used for establishing peer-to-peer connections between users
- **Firebase Firestore**: Used as a signaling server to exchange WebRTC connection details
- **Flutter Local Notifications**: Used to display notifications when new messages arrive
- **Provider**: Used for state management

## Troubleshooting

- If you encounter connection issues, ensure that all devices are on the same network or that your network allows WebRTC traffic
- For Firebase connection issues, verify that your configuration files are correctly placed and that your Firebase project is properly set up
- If notifications are not working, check that you have granted the necessary permissions to the app
