import Observation
import OSLog
import SwiftUI

@Observable
class Library: Codable {
    enum NovelsSortingMode: String, Identifiable, Codable, CaseIterable {
        case title
        case unread
        case date_added
        case date_updated

        var id: String {
            rawValue
        }

        var name: String {
            switch self {
                case .title:
                    return "Title"
                case .unread:
                    return "Unread"
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
                case .unread:
                    return {
                        if $0.chaptersRead.count == 0 && $1.chaptersRead.count != 0 {
                            return true
                        }
                        
                        if $0.chaptersRead.count != 0 && $1.chaptersRead.count == 0 {
                            return false
                        }
                        
                        return $0.title < $1.title
                    }
                case .date_added:
                    return { $0.dateAdded > $1.dateAdded }
                case .date_updated:
                    return { $0.dateUpdated > $1.dateUpdated }
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case _novels = "novels"
        case _novelsCategoryIncludes = "novelsCategoryIncludes"
        case _novelsSortingMode = "novelsSortingMode"
    }

    var novels: Set<Novel>
    var novelsCategoryIncludes: Set<Novel.Category>
    var novelsSortingMode: NovelsSortingMode

    init() {
        novels = []
        novelsCategoryIncludes = [.reading]
        novelsSortingMode = .title
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
                    self.novelsCategoryIncludes = decodedData.novelsCategoryIncludes
                    self.novelsSortingMode = decodedData.novelsSortingMode
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
