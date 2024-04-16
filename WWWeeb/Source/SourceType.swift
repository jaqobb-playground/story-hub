import Foundation

enum SourceType: Codable, CaseIterable {
    case lib_read

    var source: Source {
        switch self {
            case .lib_read:
                return Source.LibRead
        }
    }
}
