import Foundation

/// Downloads and memory-caches image bytes. Returns `Data` (not UIImage) so view models stay UIKit-free.
final class ImageLoader: ImageDataLoading {
    private let cache = NSCache<NSURL, NSData>()
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func data(for url: URL) async -> Data? {
        if let cached = cache.object(forKey: url as NSURL) { return cached as Data }
        guard let data = try? await client.rawData(from: url) else { return nil }
        cache.setObject(data as NSData, forKey: url as NSURL)
        return data
    }
}
