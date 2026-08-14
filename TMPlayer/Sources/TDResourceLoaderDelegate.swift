import Foundation
import AVFoundation
import TDLibKit

class TDResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
    private let client = TelegramClient.shared
    private let fileId: Int
    
    // Track pending requests and their download tasks
    private var pendingRequests = [AVAssetResourceLoadingRequest: Task<Void, Never>]()
    
    init(fileId: Int) {
        self.fileId = fileId
        super.init()
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let url = loadingRequest.request.url, url.scheme == "tdfile" else {
            return false
        }
        
        let task = Task { [weak self] in
            await self?.processRequest(loadingRequest)
        }
        pendingRequests[loadingRequest] = task
        
        return true
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        pendingRequests[loadingRequest]?.cancel()
        pendingRequests.removeValue(forKey: loadingRequest)
    }
    
    private func processRequest(_ request: AVAssetResourceLoadingRequest) async {
        guard let dataRequest = request.dataRequest else {
            request.finishLoading(with: NSError(domain: "TDResourceLoader", code: -1, userInfo: nil))
            return
        }
        
        let requestedOffset = dataRequest.requestedOffset
        let requestedLength = dataRequest.requestedLength
        let requestedEnd = requestedOffset + Int64(requestedLength)
        
        do {
            // Wait for file info
            let tdFile = try await client.client.getFile(fileId: fileId)
            let size = tdFile.size > 0 ? Int64(tdFile.size) : Int64(tdFile.expectedSize)
            
            if request.contentInformationRequest != nil {
                request.contentInformationRequest?.isByteRangeAccessSupported = true
                request.contentInformationRequest?.contentType = "video/mp4" // Ideally derive from extension
                request.contentInformationRequest?.contentLength = size
            }
            
            var currentOffset = requestedOffset
            
            // Loop until request is fulfilled
            while currentOffset < requestedEnd {
                if Task.isCancelled { break }
                
                // Trigger download from current offset
                let _ = try? await client.client.downloadFile(
                    fileId: fileId,
                    limit: 0,
                    offset: Int(currentOffset),
                    priority: 32,
                    synchronous: false
                )
                
                // Wait for bytes to become available
                let bytesAvailable = await waitForBytes(at: currentOffset, length: Int(requestedEnd - currentOffset))
                
                if bytesAvailable > 0 {
                    // Read bytes from file
                    let localPath = try await client.client.getFile(fileId: fileId).local.path
                    if let fileHandle = FileHandle(forReadingAtPath: localPath) {
                        try fileHandle.seek(toOffset: UInt64(currentOffset))
                        let data = fileHandle.readData(ofLength: bytesAvailable)
                        dataRequest.respond(with: data)
                        currentOffset += Int64(data.count)
                        fileHandle.closeFile()
                    }
                } else {
                    // Timeout or error, try waiting again
                    try await Task.sleep(nanoseconds: 500_000_000)
                }
            }
            
            if !Task.isCancelled {
                request.finishLoading()
            }
        } catch {
            if !Task.isCancelled {
                request.finishLoading(with: error)
            }
        }
        
        pendingRequests.removeValue(forKey: request)
    }
    
    private func waitForBytes(at offset: Int64, length: Int) async -> Int {
        do {
            var file = try await client.client.getFile(fileId: fileId)
            let checkAvailable = { (f: TDLibKit.File) -> Int in
                let start = Int64(f.local.downloadOffset)
                let end = start + Int64(f.local.downloadedPrefixSize)
                if offset >= start && offset < end {
                    return Int(min(Int64(length), end - offset))
                }
                if f.local.isDownloadingCompleted {
                    // If completed, entire file is available
                    return length
                }
                return 0
            }
            
            let available = checkAvailable(file)
            if available > 0 { return available }
            
            // Subscribe to updates until available
            for await updatedFile in client.fileUpdates {
                if updatedFile.id == fileId {
                    let av = checkAvailable(updatedFile)
                    if av > 0 { return av }
                }
            }
        } catch { }
        
        return 0
    }
}
