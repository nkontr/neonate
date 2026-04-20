import Foundation

class NetworkService {

    static let shared = NetworkService()

    private init() {}

    private let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        return URLSession(configuration: configuration)
    }()

    func get<T: Decodable>(url: URL, completion: @escaping (Result<T, Error>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        performRequest(request: request, completion: completion)
    }

    func post<T: Decodable, U: Encodable>(url: URL, body: U, completion: @escaping (Result<T, Error>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(body)
            performRequest(request: request, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    private func performRequest<T: Decodable>(request: URLRequest, completion: @escaping (Result<T, Error>) -> Void) {
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.noData))
                }
                return
            }

            do {
                let decodedObject = try JSONDecoder().decode(T.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(decodedObject))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }

        task.resume()
    }
}

enum NetworkError: Error {
    case noData
    case invalidResponse
    case decodingError

    var localizedDescription: String {
        switch self {
        case .noData:
            return "Данные не получены"
        case .invalidResponse:
            return "Некорректный ответ сервера"
        case .decodingError:
            return "Ошибка декодирования данных"
        }
    }
}
