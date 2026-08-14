import SwiftUI
import TDLibKit

struct ChatListView: View {
    @EnvironmentObject var client: TelegramClient
    @State private var chats: [Chat] = []
    
    var body: some View {
        NavigationView {
            List(chats, id: \.id) { chat in
                NavigationLink(destination: ChatDetailView(chatId: chat.id, title: chat.title)) {
                    Text(chat.title)
                }
            }
            .navigationTitle("Chats")
            .task {
                do {
                    chats = try await client.getChats()
                } catch {
                    print("Error fetching chats: \(error)")
                }
            }
        }
    }
}
