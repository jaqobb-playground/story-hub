import Foundation

class Source: Identifiable {
    let id: String
    let name: String
    let site: String
    let version: String
    let type: SourceType

    init(id: String, name: String, site: String, version: String, type: SourceType) {
        self.id = id
        self.name = name
        self.site = site
        self.version = version
        self.type = type
    }

    func parseNovel(novelPath: String) async throws -> Novel {
        fatalError("Abstract method must be overriden")
    }

    func parseNovelChapter(novelChapterPath: String) async throws -> NovelChapterContent {
        fatalError("Abstract method must be overriden")
    }

    func fetchNovels(searchTerm: String) async throws -> [NovelPreview] {
        fatalError("Abstract method must be overriden")
    }
}
