import Foundation

enum NovelSourceType: String, Identifiable, Codable, CaseIterable {
    case lib_read
    
    var id: String {
        rawValue
    }

    var source: NovelSource {
        switch self {
            case .lib_read:
                return NovelSource.LibRead
        }
    }
}
