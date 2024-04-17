import Foundation

struct Library: Codable {
    var novels: Set<Novel>
    var novelChaptersRead: [String: Set<String>]

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

    mutating func markNovelChapterAsRead(novel: Novel, novelChapter: NovelChapter) {
        novelChaptersRead[novel.path, default: Set<String>()].insert(novelChapter.path)
    }

    mutating func unmarkNovelChapterAsRead(novel: Novel, novelChapter: NovelChapter) {
        novelChaptersRead[novel.path, default: Set<String>()].remove(novelChapter.path)
    }
}
