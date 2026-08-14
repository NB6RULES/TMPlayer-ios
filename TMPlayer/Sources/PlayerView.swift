import SwiftUI
import AVKit

struct PlayerView: View {
    let fileId: Int
    @State private var player: AVPlayer?
    @State private var resourceLoaderDelegate: TDResourceLoaderDelegate?
    
    var body: some View {
        Group {
            if let player = player {
                VideoPlayer(player: player)
                    .edgesIgnoringSafeArea(.all)
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else {
                ProgressView("Loading Video...")
            }
        }
        .onAppear {
            setupPlayer()
        }
    }
    
    private func setupPlayer() {
        let url = URL(string: "tdfile://\(fileId)")!
        let asset = AVURLAsset(url: url)
        
        let delegate = TDResourceLoaderDelegate(fileId: fileId)
        self.resourceLoaderDelegate = delegate // Retain the delegate
        
        // Use a dedicated serial queue for the resource loader
        let queue = DispatchQueue(label: "com.tmplayer.resourceloader")
        asset.resourceLoader.setDelegate(delegate, queue: queue)
        
        let playerItem = AVPlayerItem(asset: asset)
        self.player = AVPlayer(playerItem: playerItem)
    }
}
