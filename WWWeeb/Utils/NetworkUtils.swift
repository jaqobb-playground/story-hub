import Foundation

struct NetworkUtils {
    static func fetchContent(from urlString: String, method: String = "GET", headers: [String: String]? = nil) async throws -> String {
        guard let components = URLComponents(string: urlString) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: components.url!)
        request.httpMethod = method

        if let headers = headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpRequestFailed(statusCode: httpResponse.statusCode)
        }

        guard let content = String(data: data, encoding: .utf8) else {
            throw NetworkError.invalidData
        }

        return content
    }
}

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case httpRequestFailed(statusCode: Int)
    case invalidResponse
    case invalidData

    var errorDescription: String? {
        switch self {
            case .invalidURL:
                return NSLocalizedString("The URL provided is invalid.", comment: "Error message shown when a URL is improperly formatted.")
            case let .httpRequestFailed(statusCode):
                return String(format: NSLocalizedString("The HTTP request failed with status code %d.", comment: "Error message shown when an HTTP request fails"), statusCode)
            case .invalidResponse:
                return NSLocalizedString("The response from the server could not be understood.", comment: "Error message shown when the HTTP response is not a valid HTTPURLResponse.")
            case .invalidData:
                return NSLocalizedString("The data received from the server was corrupt or could not be decoded.", comment: "Error message shown when data decoding fails.")
        }
    }
}
