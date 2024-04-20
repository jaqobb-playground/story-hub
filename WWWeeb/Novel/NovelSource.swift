import Foundation

class NovelSource: Identifiable {
    let id: String
    let name: String
    let site: String
    let version: String
    let type: NovelSourceType

    init(id: String, name: String, site: String, version: String, type: NovelSourceType) {
        self.id = id
        self.name = name
        self.site = site
        self.version = version
        self.type = type
    }

    func fetchNovels(searchTerm: String) async throws -> [NovelPreview] {
        fatalError("Abstract method must be overriden")
    }
    
    func parseNovel(novelPath: String) async throws -> Novel {
        fatalError("Abstract method must be overriden")
    }

    func parseNovelChapter(novelChapterPath: String) async throws -> [String] {
        fatalError("Abstract method must be overriden")
    }
}
