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
    var dateAdded: Date
    var dateUpdated: Date
    var category: Category
    var provider: NovelProvider
    var updating: Bool = false

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
        _dateAdded = try container.decode(Date.self, forKey: ._dateAdded)
        _dateUpdated = try container.decode(Date.self, forKey: ._dateUpdated)
        _category = try container.decode(Category.self, forKey: ._category)
        _provider = try container.decode(NovelProvider.self, forKey: ._provider)
    }

    var lastChapterReadNumber: Int {
        var lastChapterReadNumber = -1

        for chapter in chapters {
            if !chaptersRead.contains(chapter.path) {
                return lastChapterReadNumber
            }

            lastChapterReadNumber = chapter.number
        }

        return lastChapterReadNumber
    }

    @MainActor
    func update() async {
        updating = true

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
            AlertUtils.presentAlert(title: "Failed to Update Novel '\(title)'", message: error.localizedDescription)
        }

        updating = false
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_path, forKey: ._path)
        try container.encode(_title, forKey: ._title)
        try container.encode(_coverURL, forKey: ._coverURL)
        try container.encode(_summary, forKey: ._summary)
        try container.encode(_genres, forKey: ._genres)
        try container.encode(_authors, forKey: ._authors)
        try container.encode(_status, forKey: ._status)
        try container.encode(_chapters, forKey: ._chapters)
        try container.encode(_chaptersRead, forKey: ._chaptersRead)
        try container.encode(_dateAdded, forKey: ._dateAdded)
        try container.encode(_dateUpdated, forKey: ._dateUpdated)
        try container.encode(_category, forKey: ._category)
        try container.encode(_provider, forKey: ._provider)
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
        case unreadChapters
        case notStarted

        var id: String {
            rawValue
        }

        var name: String {
            switch self {
                case .reading:
                    return "Reading"
                case .completed:
                    return "Completed"
                case .unreadChapters:
                    return "Unread Chapter(s)"
                case .notStarted:
                    return "Not Started"
            }
        }

        func matches(novel: Novel) -> Bool {
            switch self {
                case .reading:
                    return novel.category == .reading
                case .completed:
                    return novel.category == .completed
                case .unreadChapters:
                    return novel.chapters.count > novel.chaptersRead.count
                case .notStarted:
                    return novel.chaptersRead.isEmpty
            }
        }
    }
}

extension Novel {
    enum SortingMode: String, Identifiable, Codable, CaseIterable {
        case title
        case dateAdded
        case dateUpdated

        var id: String {
            rawValue
        }

        var name: String {
            switch self {
                case .title:
                    return "Title"
                case .dateAdded:
                    return "Date added"
                case .dateUpdated:
                    return "Date updated"
            }
        }

        func comparator() -> (Novel, Novel) -> Bool {
            switch self {
                case .title:
                    return { $0.title < $1.title }
                case .dateAdded:
                    return { $0.dateAdded > $1.dateAdded }
                case .dateUpdated:
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
    var provider: NovelProvider

    init(
        path: String,
        title: String,
        number: Int,
        provider: NovelProvider
    ) {
        _path = path
        _title = title
        _number = number
        _provider = provider
    }

    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _path = try container.decode(String.self, forKey: ._path)
        _title = try container.decode(String.self, forKey: ._title)
        _number = try container.decode(Int.self, forKey: ._number)
        _provider = try container.decode(NovelProvider.self, forKey: ._provider)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_path, forKey: ._path)
        try container.encode(_title, forKey: ._title)
        try container.encode(_number, forKey: ._number)
        try container.encode(_provider, forKey: ._provider)
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
