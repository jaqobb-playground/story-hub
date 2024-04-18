import Observation
import OSLog
import SwiftUI

@Observable
class Library: Codable {
    enum CodingKeys: String, CodingKey {
        case _novels = "novels"
    }

    var novels: Set<Novel>

    init() {
        novels = Set()
    }

    func load() {
        Task.init {
            do {
                Logger.library.info("Loading library...")

                guard let data = try? Data(contentsOf: Self.fileURL()) else {
                    return
                }

                let decoder = JSONDecoder()
                let decodedData = try decoder.decode(Library.self, from: data)

                DispatchQueue.main.async {
                    self.novels = decodedData.novels
                }
            } catch {
                // TODO: Implement migration system for outdated libraries.
                Logger.library.warning("Failed to load library: \(error.localizedDescription)")
            }
        }
    }

    func save() {
        Task.init {
            do {
                Logger.library.info("Saving library...")

                let encoder = JSONEncoder()
                let encodedData = try encoder.encode(self)
                try encodedData.write(to: Self.fileURL())
            } catch {
                Logger.library.warning("Failed to save library: \(error.localizedDescription)")
            }
        }
    }

    private static func fileURL() throws -> URL {
        return try FileManager.default
            .url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            .appendingPathComponent("library.data")
    }
}

extension Set where Element == Novel {
    subscript(_ path: String) -> Novel? {
        return first { $0.path == path }
    }
}

struct LibraryKey: EnvironmentKey {
    static let defaultValue: Library = Library()
}

extension EnvironmentValues {
    var library: Library {
        get { self[LibraryKey.self] }
        set { self[LibraryKey.self] = newValue }
    }
}

struct LibraryEnvironmentModifier: ViewModifier {
    let library: Library

    func body(content: Content) -> some View {
        content.environment(\.library, library)
    }
}
