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
        _novels = []
    }

    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _novels = try container.decodeIfPresent(Set<Novel>.self, forKey: ._novels) ?? []
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_novels, forKey: ._novels)
    }
}

extension Library {
    static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "library")
}

extension Library {
    static func load() -> Library {
        do {
            Library.logger.info("Loading library...")

            guard let data = try? Data(contentsOf: Self.fileURL()) else {
                return Library()
            }

            let decoder = JSONDecoder()
            let decodedLibrary = try decoder.decode(Library.self, from: data)

            return decodedLibrary
        } catch {
            Library.logger.warning("Failed to load library: \(error.localizedDescription)")
            return Library()
        }
    }

    static func save(_ library: Library) {
        do {
            Library.logger.info("Saving library...")

            let encoder = JSONEncoder()
            let encodedLibrary = try encoder.encode(library)

            try encodedLibrary.write(to: Self.fileURL())
        } catch {
            Library.logger.warning("Failed to save library: \(error.localizedDescription)")
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
