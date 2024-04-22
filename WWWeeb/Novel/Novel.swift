import Observation
import OSLog
import SwiftUI

@Observable
class Novel: Codable, Hashable {
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
        case _lastChapterReadNumber = "lastChapterReadNumber"
        case _dateAdded = "dateAdded"
        case _dateUpdated = "dateUpdated"
        case _category = "category"
        case _provider = "provider"
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
    var lastChapterReadNumber: Int
    var dateAdded: Date
    var dateUpdated: Date
    var category: Category
    var categoryBinding: Binding<Category> {
        Binding(
            get: { self.category },
            set: { self.category = $0 }
        )
    }

    var provider: NovelProvider

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
        lastChapterReadNumber: Int,
        dateAdded: Date,
        dateUpdated: Date,
        category: Category,
        provider: NovelProvider
    ) {
        _path = path
        _title = title
        _coverURL = coverURL
        _summary = summary
        _genres = genres
        _authors = authors
        _status = status
        _chapters = chapters
        _chaptersRead = chaptersRead
        _lastChapterReadNumber = lastChapterReadNumber
        _dateAdded = dateAdded
        _dateUpdated = dateUpdated
        _category = category
        _provider = provider
    }
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _path = try container.decode(String.self, forKey: ._path)
        _title = try container.decode(String.self, forKey: ._title)
        _coverURL = try container.decode(String.self, forKey: ._coverURL)
        _summary = try container.decode([String].self, forKey: ._summary)
        _genres = try container.decode([String].self, forKey: ._genres)
        _authors = try container.decode([String].self, forKey: ._authors)
        _status = try container.decode(String.self, forKey: ._status)
        _chapters = try container.decode([NovelChapter].self, forKey: ._chapters)
        _chaptersRead = try container.decode(Set<String>.self, forKey: ._chaptersRead)
        _lastChapterReadNumber = try container.decode(Int.self, forKey: ._lastChapterReadNumber)
        _dateAdded = try container.decode(Date.self, forKey: ._dateAdded)
        _dateUpdated = try container.decode(Date.self, forKey: ._dateUpdated)
        _category = try container.decode(Category.self, forKey: ._category)
        _provider = try container.decode(NovelProvider.self, forKey: ._provider)
    }

    func update() async {
        do {
            let updatedNovel = try await provider.implementation.parseNovel(path: path)

            title = updatedNovel.title
            coverURL = updatedNovel.coverURL
            summary = updatedNovel.summary
            genres = updatedNovel.genres
            authors = updatedNovel.authors
            status = updatedNovel.status

            let lastChapterNumber = chapters.last?.number ?? -1

            let newChapters = updatedNovel.chapters.filter { $0.number > lastChapterNumber }
            if !newChapters.isEmpty {
                chapters.append(contentsOf: newChapters)

                dateUpdated = Date.now
            }
        } catch {
            AlertUtils.showAlert(title: "Failed to Update Novel '\(title)'", message: error.localizedDescription)
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }

    static func == (lhs: Novel, rhs: Novel) -> Bool {
        return lhs.path == rhs.path
    }
}

extension Novel {
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
}

extension Novel {
    enum Filter: String, Identifiable, Codable, CaseIterable {
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

        func matches(novel: Novel) -> Bool {
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
}

extension Novel {
    enum SortingMode: String, Identifiable, Codable, CaseIterable {
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
        case _provider = "provider"
    }

    var path: String
    var title: String
    var number: Int
    var releaseTime: Int64?
    var content: [String]?
    var provider: NovelProvider

    init(
        path: String,
        title: String,
        number: Int,
        releaseTime: Int64?,
        content: [String]?,
        provider: NovelProvider
    ) {
        _path = path
        _title = title
        _number = number
        _releaseTime = releaseTime
        _content = content
        _provider = provider
    }
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _path = try container.decode(String.self, forKey: ._path)
        _title = try container.decode(String.self, forKey: ._title)
        _number = try container.decode(Int.self, forKey: ._number)
        _releaseTime = try container.decode(Int64?.self, forKey: ._releaseTime)
        _content = try container.decode([String]?.self, forKey: ._content)
        _provider = try container.decode(NovelProvider.self, forKey: ._provider)
    }

    func fetchContent() async {
        do {
            content = try await provider.implementation.parseNovelChapter(path: path)
        } catch {
            AlertUtils.showAlert(title: "Failed to Fetch Chapter '\(title)' Content", message: error.localizedDescription)
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
    subscript(_ path: String) -> Element? {
        return first { $0.path == path }
    }
    
    func splitIntoChunks(of chunkSize: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: chunkSize).map { startIndex in
            let endIndex = Swift.min(startIndex + chunkSize, self.count)
            return Array(self[startIndex ..< endIndex])
        }
    }
}

struct NovelPreview: Hashable {
    let path: String
    let title: String
    let coverURL: String
    let provider: NovelProvider

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
