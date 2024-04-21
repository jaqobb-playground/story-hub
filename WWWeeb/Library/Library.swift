import Observation
import OSLog
import SwiftUI

@Observable
class Library: Codable {
    static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "library")

    enum NovelsInclude: String, Identifiable, Codable, CaseIterable {
        case reading
        case completed
        case unread

        var id: String {
            rawValue
        }

        var name: String {
            switch self {
                case .reading:
                    return "Reading"
                case .completed:
                    return "Completed"
                case .unread:
                    return "Unread"
            }
        }

        func shouldInclude(novel: Novel) -> Bool {
            switch self {
                case .reading:
                    return novel.category == .reading
                case .completed:
                    return novel.category == .completed
                case .unread:
                    return novel.chaptersRead.isEmpty
            }
        }
    }

    enum NovelsSortingMode: String, Identifiable, Codable, CaseIterable {
        case title
        case date_added
        case date_updated

        var id: String {
            rawValue
        }

        var name: String {
            switch self {
                case .title:
                    return "Title"
                case .date_added:
                    return "Date added"
                case .date_updated:
                    return "Date updated"
            }
        }

        func comparator() -> (Novel, Novel) -> Bool {
            switch self {
                case .title:
                    return { $0.title < $1.title }
                case .date_added:
                    return { $0.dateAdded > $1.dateAdded }
                case .date_updated:
                    return { $0.dateUpdated > $1.dateUpdated }
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case _novels = "novels"
        case _novelsIncludes = "novelsIncludes"
        case _novelsSortingMode = "novelsSortingMode"
    }

    var novels: Set<Novel>
    var novelsIncludes: Set<NovelsInclude>
    var novelsSortingMode: NovelsSortingMode

    init() {
        novels = []
        novelsIncludes = [.reading]
        novelsSortingMode = .title
    }

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
            // TODO: Implement migration system for outdated libraries.
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
