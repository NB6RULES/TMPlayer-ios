import SwiftUI
import TDLibKit

struct ChatDetailView: View {
    @EnvironmentObject var client: TelegramClient
    let chatId: Int64
    let title: String
    
    @State private var videos: [Message] = []
    
    var body: some View {
        List(videos, id: \.id) { message in
            if case let .messageVideo(videoContent) = message.content {
                NavigationLink(destination: PlayerView(fileId: videoContent.video.video.id)) {
                    HStack {
                        Image(systemName: "video.fill")
                        VStack(alignment: .leading) {
                            Text(videoContent.video.fileName ?? "Video")
                            Text("\(videoContent.video.duration) sec")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(title)
        .task {
            do {
                videos = try await client.getVideos(in: chatId)
            } catch {
                print("Failed to fetch videos: \(error)")
            }
        }
    }
}
