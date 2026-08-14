import Foundation
import TDLibKit

@MainActor
final class TelegramClient: ObservableObject {
    static let shared = TelegramClient()
    
    let manager: TDLibClientManager
    let client: TDLibClient
    
    @Published var authState: AuthorizationState?
    @Published var qrCodeUrl: String?
    
    // File update stream
    private var fileUpdatesContinuation: AsyncStream<TDLibKit.File>.Continuation?
    var fileUpdates: AsyncStream<TDLibKit.File> {
        AsyncStream { continuation in
            self.fileUpdatesContinuation = continuation
        }
    }
    
    init() {
        manager = TDLibClientManager()
        // Create the client
        client = manager.createClient(updateHandler: { [weak self] data in
            self?.handleUpdate(data: data)
        })
        
        Task {
            await start()
        }
    }
    
    private func handleUpdate(data: Data) {
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let update = try decoder.decode(Update.self, from: data)
            Task { @MainActor in
                self.processUpdate(update)
            }
        } catch {
            // Unhandled update or error parsing
        }
    }
    
    private func processUpdate(_ update: Update) {
        switch update {
        case .updateAuthorizationState(let state):
            self.authState = state.authorizationState
            handleAuthState(state.authorizationState)
        case .updateFile(let updateFile):
            self.fileUpdatesContinuation?.yield(updateFile.file)
        default:
            break
        }
    }
    
    func start() async {
        do {
            try await client.setLogVerbosityLevel(newVerbosityLevel: 1)
            let _ = try await client.getAuthorizationState()
        } catch {
            print("Failed to start TDLib: \(error)")
        }
    }
    
    private func handleAuthState(_ state: AuthorizationState) {
        Task {
            do {
                switch state {
                case .authorizationStateWaitTdlibParameters:
                    try await client.setTdlibParameters(
                        apiHash: "YOUR_API_HASH", // TODO: Replace or inject from env
                        apiId: 123456,            // TODO: Replace or inject from env
                        applicationVersion: "1.0",
                        databaseDirectory: getDocsDir().appendingPathComponent("tdlib").path,
                        deviceModel: "iOS",
                        enableStorageOptimizer: true,
                        filesDirectory: getDocsDir().appendingPathComponent("tdlib_files").path,
                        ignoreFileNames: false,
                        systemLanguageCode: "en",
                        systemVersion: "16.0",
                        useChatInfoDatabase: true,
                        useFileDatabase: true,
                        useMessageDatabase: true,
                        useSecretChats: false,
                        useTestDc: false
                    )
                case .authorizationStateWaitEncryptionKey:
                    try await client.checkDatabaseEncryptionKey(encryptionKey: "")
                case .authorizationStateWaitPhoneNumber:
                    // Request QR code authentication
                    try await client.requestQrCodeAuthentication(otherUserIds: [])
                case .authorizationStateWaitOtherDeviceConfirmation(let confirm):
                    self.qrCodeUrl = confirm.link
                case .authorizationStateReady:
                    print("TDLib is ready!")
                    self.qrCodeUrl = nil
                default:
                    break
                }
            } catch {
                print("Error handling auth state: \(error)")
            }
        }
    }
    
    private func getDocsDir() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func getChats() async throws -> [Chat] {
        let chatList = try await client.getChats(chatList: .chatListMain, limit: 100)
        var chats = [Chat]()
        for chatId in chatList.chatIds {
            let chat = try await client.getChat(chatId: chatId)
            chats.append(chat)
        }
        return chats
    }
    
    func getVideos(in chatId: Int64) async throws -> [Message] {
        let response = try await client.searchChatMessages(
            chatId: chatId,
            filter: .searchMessagesFilterVideo,
            fromMessageId: 0,
            limit: 50,
            messageThreadId: 0,
            offset: 0,
            query: "",
            savedMessagesTopicId: 0,
            senderId: nil
        )
        return response.messages
    }
}
