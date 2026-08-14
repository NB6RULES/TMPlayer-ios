import SwiftUI
import CoreImage.CIFilterBuiltins

struct LoginView: View {
    @EnvironmentObject var client: TelegramClient
    
    var body: some View {
        VStack {
            Text("Log in to Telegram")
                .font(.largeTitle)
                .bold()
                .padding()
            
            Text("1. Open Telegram on your phone\n2. Go to Settings > Devices > Link Desktop Device\n3. Point your phone at this screen")
                .multilineTextAlignment(.center)
                .padding()
            
            if let qrCode = client.qrCodeUrl {
                Image(uiImage: generateQRCode(from: qrCode))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .padding()
            } else {
                ProgressView()
                    .frame(width: 250, height: 250)
            }
        }
    }
    
    func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            // Scale up to avoid blurriness
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            if let cgimg = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}
