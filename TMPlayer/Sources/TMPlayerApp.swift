import SwiftUI

@main
struct TMPlayerApp: App {
    @StateObject private var telegramClient = TelegramClient.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(telegramClient)
        }
    }
}
