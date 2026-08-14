import SwiftUI
import AVKit

struct PlayerView: View {
    let fileId: Int
    @EnvironmentObject var telegramClient: TelegramClient
    @State private var player = AVPlayer()
    @State private var loaderDelegate: TDResourceLoaderDelegate?
    
    var body: some View {
        VideoPlayer(player: player)
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                setupPlayer()
            }
            .onDisappear {
                player.pause()
                loaderDelegate = nil
            }
    }
    
    private func setupPlayer() {
        let url = URL(string: "tdfile://\(fileId)")!
        let asset = AVURLAsset(url: url)
        
        let delegate = TDResourceLoaderDelegate(client: telegramClient)
        self.loaderDelegate = delegate
        
        // Use a dedicated serial queue for the resource loader
        let queue = DispatchQueue(label: "com.tmplayer.resourceloader")
        asset.resourceLoader.setDelegate(delegate, queue: queue)
        
        let playerItem = AVPlayerItem(asset: asset)
        self.player.replaceCurrentItem(with: playerItem)
        self.player.play()
    }
}
