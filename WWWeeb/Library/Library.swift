import Observation
import OSLog
import SwiftUI

@Observable
class Library: Codable {
    enum CodingKeys: String, CodingKey {
        case _novels = "novels"
        case _novelChaptersRead = "novelChaptersRead"
    }

    var novels: Set<Novel>
    var novelChaptersRead: [String: Set<String>]

    init() {
        novels = Set()
        novelChaptersRead = [:]
    }

    func getNovel(novelPath: String) -> Novel? {
        return novels.first { $0.path == novelPath }
    }

    func getNovelChaptersRead(novel: Novel) -> Set<String> {
        return novelChaptersRead[novel.path, default: Set<String>()]
    }

    func getNovelChaptersMarkedAsRead(novel: Novel) -> Int {
        return getNovelChaptersRead(novel: novel).count
    }

    func isNovelChapterMarkedAsRead(novel: Novel, novelChapter: NovelChapter) -> Bool {
        return getNovelChaptersRead(novel: novel).contains(novelChapter.path)
    }

    func markNovelChapterAsRead(novel: Novel, novelChapter: NovelChapter) {
        novelChaptersRead[novel.path, default: Set<String>()].insert(novelChapter.path)
    }

    func unmarkNovelChapterAsRead(novel: Novel, novelChapter: NovelChapter) {
        novelChaptersRead[novel.path, default: Set<String>()].remove(novelChapter.path)
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
                    self.novelChaptersRead = decodedData.novelChaptersRead
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
