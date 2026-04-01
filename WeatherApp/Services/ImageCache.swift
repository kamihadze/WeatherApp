import UIKit

final class ImageCache {

    static let shared = ImageCache()

    private let cache = NSCache<NSString, UIImage>()

    private init() {}

    func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        let fullURL = urlString.hasPrefix("http") ? urlString : "https:\(urlString)"

        if let cached = cache.object(forKey: fullURL as NSString) {
            completion(cached)
            return
        }

        guard let url = URL(string: fullURL) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            self?.cache.setObject(image, forKey: fullURL as NSString)
            DispatchQueue.main.async { completion(image) }
        }.resume()
    }
}
