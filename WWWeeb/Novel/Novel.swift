import Foundation
import SwiftData

struct Novel: Codable, Hashable {
    var path: String
    var title: String
    var coverURL: String
    var summary: [String]
    var genres: [String]
    var authors: [String]
    var status: String
    var chapters: [NovelChapter]
    var sourceType: SourceType

    func splitChaptersIntoChunks(chunkSize: Int) -> [[NovelChapter]] {
        return stride(from: 0, to: chapters.count, by: chunkSize).map { startIndex in
            let endIndex = min(startIndex + chunkSize, chapters.count)
            return Array(chapters[startIndex ..< endIndex])
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }

    static func == (lhs: Novel, rhs: Novel) -> Bool {
        return lhs.path == rhs.path
    }
}

struct NovelChapter: Codable, Hashable {
    let path: String
    let title: String
    let number: Int
    let releaseTime: Int64?

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

struct NovelPreview: Codable, Hashable {
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
    case parsingError(description: String)
    case fetchingError(description: String)
}
