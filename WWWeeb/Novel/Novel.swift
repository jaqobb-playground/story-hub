import Observation
import OSLog

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
    var sourceType: SourceType

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
        sourceType: SourceType
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

    func splitChaptersIntoChunks(chunkSize: Int) -> [[NovelChapter]] {
        return stride(from: 0, to: chapters.count, by: chunkSize).map { startIndex in
            let endIndex = min(startIndex + chunkSize, chapters.count)
            return Array(chapters[startIndex ..< endIndex])
        }
    }

    func update() async {
        let novelTitle = title
        let novelChaptersCount = chapters.count
        
        Logger.library.info("Updating novel '\(novelTitle)'...")

        do {
            let newNovel = try await sourceType.source.parseNovel(novelPath: path)

            title = newNovel.title
            coverURL = newNovel.coverURL
            summary = newNovel.summary
            genres = newNovel.genres
            authors = newNovel.authors
            status = newNovel.status
            chapters = newNovel.chapters
            
            let newNovelChaptersCount = chapters.count
            if newNovelChaptersCount != novelChaptersCount {
                dateUpdated = Date.now
            }

            Logger.library.info("Novel '\(novelTitle)' updated; \(newNovelChaptersCount - novelChaptersCount) new chapters found.")
        } catch {
            Logger.library.warning("Failed to update novel '\(novelTitle)': \(error.localizedDescription)")

            AlertUtils.showAlert(title: "Failed to update novel '\(novelTitle)'", message: error.localizedDescription)
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
    }

    var path: String
    var title: String
    var number: Int
    var releaseTime: Int64?

    init(path: String, title: String, number: Int, releaseTime: Int64?) {
        self.path = path
        self.title = title
        self.number = number
        self.releaseTime = releaseTime
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }

    static func == (lhs: NovelChapter, rhs: NovelChapter) -> Bool {
        return lhs.path == rhs.path
    }
}

struct NovelChapterContent {
    let title: String
    let contents: [String]
}

struct NovelPreview: Hashable {
    let path: String
    let title: String
    let coverURL: String
    let sourceType: SourceType

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
