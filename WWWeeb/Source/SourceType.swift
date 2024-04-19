import Foundation

enum SourceType: String, Identifiable, Codable, CaseIterable {
    case lib_read
    
    var id: String {
        rawValue
    }

    var source: Source {
        switch self {
            case .lib_read:
                return Source.LibRead
        }
    }
}
