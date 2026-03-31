import Foundation

enum WeatherError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Некорректный URL запроса"
        case .networkError(let error):
            return "Ошибка сети: \(error.localizedDescription)"
        case .decodingError:
            return "Ошибка обработки данных"
        case .serverError(let code):
            return "Ошибка сервера: \(code)"
        }
    }
}

final class WeatherService {

    private let apiKey = "fa8b3df74d4042b9aa7135114252304"
    private let baseURL = "http://api.weatherapi.com/v1"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchForecast(
        latitude: Double,
        longitude: Double,
        completion: @escaping (Result<ForecastResponse, WeatherError>) -> Void
    ) {
        let urlString = "\(baseURL)/forecast.json?key=\(apiKey)&q=\(latitude),\(longitude)&days=3&lang=ru"
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }

        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(.networkError(error)))
                }
                return
            }

            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                DispatchQueue.main.async {
                    completion(.failure(.serverError(httpResponse.statusCode)))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(.networkError(URLError(.badServerResponse))))
                }
                return
            }

            do {
                let forecast = try JSONDecoder().decode(ForecastResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(forecast))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.decodingError(error)))
                }
            }
        }
        task.resume()
    }
}
