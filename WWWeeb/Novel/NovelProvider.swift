import Foundation

enum NovelProvider: String, Identifiable, Codable, CaseIterable {
    case freeWebNovel

    var id: String {
        rawValue
    }

    var implementation: NovelProvider.Implementation {
        switch self {
            case .freeWebNovel:
                return NovelProvider.Implementation.FreeWebNovel
        }
    }
}

extension NovelProvider {
    struct Details {
        let name: String
        let site: String
        let version: String
        let batchSize: Int
        let batchFetchPeriodNanos: UInt64
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
