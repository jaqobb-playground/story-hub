import Observation
import OSLog
import SwiftUI

@Observable
class Settings: Codable {
    enum CodingKeys: String, CodingKey {
        case _appearanceId = "appearanceId"
        case _novelProviders = "novelProviders"
        case _novelChapterChunkSize = "novelChapterChunkSize"
        case _novelChapterFontSize = "novelChapterFontSize"
        case _novelChapterHorizontalPadding = "novelChapterHorizontalPadding"
        case _novelChapterVerticalPadding = "novelChapterVerticalPadding"
        case _markNovelChapterAsReadWhenFinished = "markNovelChapterAsReadWhenFinished"
        case _markNovelChapterAsReadWhenSwitching = "markNovelChapterAsReadWhenSwitching"
    }

    var appearanceId: Int
    var appearanceIdBinding: Binding<Int> {
        Binding(
            get: { self.appearanceId },
            set: { self.appearanceId = $0 }
        )
    }

    var novelProviders: Set<NovelProvider>
    var novelChapterFontSize: CGFloat
    var novelChapterFontSizeBinding: Binding<CGFloat> {
        Binding(
            get: { self.novelChapterFontSize },
            set: { self.novelChapterFontSize = $0 }
        )
    }
    var novelChapterChunkSize: Int
    var novelChapterChunkSizeBinding: Binding<Int> {
        Binding(
            get: { self.novelChapterChunkSize },
            set: { self.novelChapterChunkSize = $0 }
        )
    }

    var novelChapterHorizontalPadding: CGFloat
    var novelChapterHorizontalPaddingBinding: Binding<CGFloat> {
        Binding(
            get: { self.novelChapterHorizontalPadding },
            set: { self.novelChapterHorizontalPadding = $0 }
        )
    }

    var novelChapterVerticalPadding: CGFloat
    var novelChapterVerticalPaddingBinding: Binding<CGFloat> {
        Binding(
            get: { self.novelChapterVerticalPadding },
            set: { self.novelChapterVerticalPadding = $0 }
        )
    }

    var markNovelChapterAsReadWhenFinished: Bool
    var markNovelChapterAsReadWhenFinishedBinding: Binding<Bool> {
        Binding(
            get: { self.markNovelChapterAsReadWhenFinished },
            set: { self.markNovelChapterAsReadWhenFinished = $0 }
        )
    }

    var markNovelChapterAsReadWhenSwitching: Bool
    var markNovelChapterAsReadWhenSwitchingBinding: Binding<Bool> {
        Binding(
            get: { self.markNovelChapterAsReadWhenSwitching },
            set: { self.markNovelChapterAsReadWhenSwitching = $0 }
        )
    }

    init() {
        _appearanceId = 0
        _novelProviders = []
        _novelChapterFontSize = 18
        _novelChapterChunkSize = 100
        _novelChapterHorizontalPadding = 12
        _novelChapterVerticalPadding = 6
        _markNovelChapterAsReadWhenFinished = true
        _markNovelChapterAsReadWhenSwitching = true
    }

    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _appearanceId = try container.decodeIfPresent(Int.self, forKey: ._appearanceId) ?? 0
        _novelProviders = try container.decodeIfPresent(Set<NovelProvider>.self, forKey: ._novelProviders) ?? []
        _novelChapterFontSize = try container.decodeIfPresent(CGFloat.self, forKey: ._novelChapterFontSize) ?? 18
        _novelChapterChunkSize = try container.decodeIfPresent(Int.self, forKey: ._novelChapterChunkSize) ?? 100
        _novelChapterHorizontalPadding = try container.decodeIfPresent(CGFloat.self, forKey: ._novelChapterHorizontalPadding) ?? 12
        _novelChapterVerticalPadding = try container.decodeIfPresent(CGFloat.self, forKey: ._novelChapterVerticalPadding) ?? 6
        _markNovelChapterAsReadWhenFinished = try container.decodeIfPresent(Bool.self, forKey: ._markNovelChapterAsReadWhenFinished) ?? true
        _markNovelChapterAsReadWhenSwitching = try container.decodeIfPresent(Bool.self, forKey: ._markNovelChapterAsReadWhenSwitching) ?? true
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_appearanceId, forKey: ._appearanceId)
        try container.encode(_novelProviders, forKey: ._novelProviders)
        try container.encode(_novelChapterFontSize, forKey: ._novelChapterFontSize)
        try container.encode(_novelChapterChunkSize, forKey: ._novelChapterChunkSize)
        try container.encode(_novelChapterHorizontalPadding, forKey: ._novelChapterHorizontalPadding)
        try container.encode(_novelChapterVerticalPadding, forKey: ._novelChapterVerticalPadding)
        try container.encode(_markNovelChapterAsReadWhenFinished, forKey: ._markNovelChapterAsReadWhenFinished)
        try container.encode(_markNovelChapterAsReadWhenSwitching, forKey: ._markNovelChapterAsReadWhenSwitching)
    }
}

extension Settings {
    static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "settings")
}

extension Settings {
    static func load() -> Settings {
        do {
            Settings.logger.info("Loading settings...")

            guard let data = try? Data(contentsOf: Self.fileURL()) else {
                return Settings()
            }

            let decoder = JSONDecoder()
            let decodedSettings = try decoder.decode(Settings.self, from: data)

            return decodedSettings
        } catch {
            Settings.logger.warning("Failed to load settings: \(error.localizedDescription)")
            return Settings()
        }
    }

    static func save(_ settings: Settings) {
        do {
            Settings.logger.info("Saving settings...")

            let encoder = JSONEncoder()
            let encodedSettings = try encoder.encode(settings)

            try encodedSettings.write(to: Self.fileURL())
        } catch {
            Settings.logger.warning("Failed to save settings: \(error.localizedDescription)")
        }
    }

    private static func fileURL() throws -> URL {
        return try FileManager.default
            .url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            .appendingPathComponent("settings.data")
    }
}

struct SettingsKey: EnvironmentKey {
    static let defaultValue: Settings = Settings()
}

extension EnvironmentValues {
    var settings: Settings {
        get { self[SettingsKey.self] }
        set { self[SettingsKey.self] = newValue }
    }
}

struct SettingsEnvironmentModifier: ViewModifier {
    let settings: Settings

    func body(content: Content) -> some View {
        content.environment(\.settings, settings)
    }
}
