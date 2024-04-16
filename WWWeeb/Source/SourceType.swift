import Foundation

enum SourceType: Codable, CaseIterable {
    case libRead

    var source: Source {
        switch self {
            case .libRead:
                return Source.libRead
        }
    }
}
