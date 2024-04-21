import Observation
import OSLog
import SwiftUI

@Observable
class Novel: Codable, Hashable {
    enum Category: String, Identifiable, Codable, CaseIterable {
        case reading
        case completed

        var id: String {
            rawValue
        }

        var name: String {
            switch self {
                case .reading:
                    return "Reading"
                case .completed:
                    return "Completed"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case _path = "path"
        case _title = "title"
        case _coverURL = "coverURL"
        case _summary = "summary"
        case _genres = "genres"
        case _authors = "authors"
        case _status = "status"
        case _chapters = "chapters"
        case _chaptersRead = "chaptersRead"
        case _dateAdded = "dateAdded"
        case _dateUpdated = "dateUpdated"
        case _category = "category"
        case _sourceType = "sourceType"
    }

    var path: String
    var title: String
    var coverURL: String
    var summary: [String]
    var genres: [String]
    var authors: [String]
    var status: String
    var chapters: [NovelChapter]
    var chaptersRead: Set<String>
    var dateAdded: Date
    var dateUpdated: Date
    var category: Category
    var categoryBinding: Binding<Category> {
        Binding(
            get: { self.category },
            set: { self.category = $0 }
        )
    }

    var sourceType: NovelSourceType

    init(
        path: String,
        title: String,
        coverURL: String,
        summary: [String],
        genres: [String],
        authors: [String],
        status: String,
        chapters: [NovelChapter],
        chaptersRead: Set<String>,
        dateAdded: Date,
        dateUpdated: Date,
        category: Category,
        sourceType: NovelSourceType
    ) {
        self.path = path
        self.title = title
        self.coverURL = coverURL
        self.summary = summary
        self.genres = genres
        self.authors = authors
        self.status = status
        self.chapters = chapters
        self.chaptersRead = chaptersRead
        self.dateAdded = dateAdded
        self.dateUpdated = dateUpdated
        self.category = category
        self.sourceType = sourceType
    }

    func update() async {
        do {
            let newNovel = try await sourceType.source.parseNovel(novelPath: path)

            title = newNovel.title
            coverURL = newNovel.coverURL
            summary = newNovel.summary
            genres = newNovel.genres
            authors = newNovel.authors
            status = newNovel.status

            let lastChapterNumber = chapters.last?.number ?? -1

            let newChapters = newNovel.chapters.filter { $0.number > lastChapterNumber }
            if !newChapters.isEmpty {
                chapters.append(contentsOf: newChapters)

                dateUpdated = Date.now
            }
        } catch {
            AlertUtils.showAlert(title: "Failed to update novel '\(title)'", message: error.localizedDescription)
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }

    static func == (lhs: Novel, rhs: Novel) -> Bool {
        return lhs.path == rhs.path
    }
}

extension Set where Element == Novel {
    subscript(_ path: String) -> Novel? {
        return first { $0.path == path }
    }
}

@Observable
class NovelChapter: Codable, Hashable {
    enum CodingKeys: String, CodingKey {
        case _path = "path"
        case _title = "title"
        case _number = "number"
        case _releaseTime = "releaseTime"
        case _content = "content"
        case _sourceType = "sourceType"
    }

    var path: String
    var title: String
    var number: Int
    var releaseTime: Int64?
    var content: [String]?
    var sourceType: NovelSourceType

    init(
        path: String,
        title: String,
        number: Int,
        releaseTime: Int64?,
        content: [String]?,
        sourceType: NovelSourceType
    ) {
        self.path = path
        self.title = title
        self.number = number
        self.releaseTime = releaseTime
        self.content = content
        self.sourceType = sourceType
    }

    func fetchContent() async {
        do {
            content = try await sourceType.source.parseNovelChapter(novelChapterPath: path)
        } catch {
            AlertUtils.showAlert(title: "Failed to fetch novel chapter's '\(title)' content", message: error.localizedDescription)
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }

    static func == (lhs: NovelChapter, rhs: NovelChapter) -> Bool {
        return lhs.path == rhs.path
    }
}

extension Array where Element == NovelChapter {
    func splitIntoChunks(of chunkSize: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: chunkSize).map { startIndex in
            let endIndex = Swift.min(startIndex + chunkSize, self.count)
            return Array(self[startIndex ..< endIndex])
        }
    }
}

struct NovelPreview: Hashable {
    let path: String
    let title: String
    let coverURL: String
    let sourceType: NovelSourceType

    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }

    static func == (lhs: NovelPreview, rhs: NovelPreview) -> Bool {
        return lhs.path == rhs.path
    }
}

enum NovelError: Error {
    case parse(description: String)
    case fetch(description: String)
}
