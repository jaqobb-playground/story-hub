import Foundation

struct URLUtils {
    static func fetchHTML(from urlString: String, method: String = "GET", headers: [String: String]? = nil, query: [String: String]? = nil) async throws -> String {
        guard var components = URLComponents(string: urlString) else {
            throw NSError(domain: "Invalid URL", code: 0, userInfo: nil)
        }

        if let queryItems = query?.map({ URLQueryItem(name: $0, value: $1) }) {
            components.queryItems = queryItems
        }

        var request = URLRequest(url: components.url!)
        request.httpMethod = method

        if let headers = headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200 ... 299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "HTTP Error", code: 0, userInfo: nil)
        }

        guard let htmlString = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "Invalid Data", code: 0, userInfo: nil)
        }

        return htmlString
    }
}
