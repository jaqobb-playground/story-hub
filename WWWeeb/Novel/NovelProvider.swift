import Foundation

enum NovelProvider: String, Identifiable, Codable, CaseIterable {
    case freeWebNovel
    case scribbleHub
    case mtlNovel

    var id: String {
        rawValue
    }

    var implementation: NovelProvider.Implementation {
        switch self {
            case .freeWebNovel:
                return NovelProvider.Implementation.FreeWebNovel
            case .scribbleHub:
                return NovelProvider.Implementation.ScribbleHub
            case .mtlNovel:
                return NovelProvider.Implementation.MTLNovel
        }
    }
}

extension NovelProvider {
    struct Details {
        let name: String
        let site: String
    }
}

extension NovelProvider {
    class Implementation {
        let provider: NovelProvider
        let details: NovelProvider.Details

        init(provider: NovelProvider, details: NovelProvider.Details) {
            self.provider = provider
            self.details = details
        }

        func fetchNovels(searchTerm: String) async throws -> [NovelPreview] {
            fatalError("Abstract method must be overriden")
        }

        func parseNovel(path: String) async throws -> Novel {
            fatalError("Abstract method must be overriden")
        }

        func parseNovelChapter(path: String) async throws -> [String] {
            fatalError("Abstract method must be overriden")
        }
    }
}
