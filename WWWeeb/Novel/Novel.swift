import Observation
import OSLog

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
    var sourceType: SourceType

    init(path: String, title: String, coverURL: String, summary: [String], genres: [String], authors: [String], status: String, chapters: [NovelChapter], chaptersRead: Set<String>, sourceType: SourceType) {
        self.path = path
        self.title = title
        self.coverURL = coverURL
        self.summary = summary
        self.genres = genres
        self.authors = authors
        self.status = status
        self.chapters = chapters
        self.chaptersRead = chaptersRead
        self.sourceType = sourceType
    }
    
    func splitChaptersIntoChunks(chunkSize: Int) -> [[NovelChapter]] {
        return stride(from: 0, to: chapters.count, by: chunkSize).map { startIndex in
            let endIndex = min(startIndex + chunkSize, chapters.count)
            return Array(chapters[startIndex ..< endIndex])
        }
    }

    func update() async {
        Logger.library.info("Updating novel '\(self.title)'...")

        let chaptersCount = self.chapters.count
        do {
            let novelUpdated = try await sourceType.source.parseNovel(novelPath: path)
            
            title = novelUpdated.title
            coverURL = novelUpdated.coverURL
            summary = novelUpdated.summary
            genres = novelUpdated.genres
            authors = novelUpdated.authors
            status = novelUpdated.status
            chapters = novelUpdated.chapters

            Logger.library.info("Novel '\(self.title)' updated; \(self.chapters.count - chaptersCount) new chapters found.")
        } catch {
            Logger.library.warning("Failed to update novel '\(self.title)': \(error.localizedDescription)")

            AlertUtils.showAlert(title: "Failed to update novel '\(self.title)'", message: error.localizedDescription)
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }

    static func == (lhs: Novel, rhs: Novel) -> Bool {
        return lhs.path == rhs.path
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
