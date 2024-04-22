import SwiftData
import SwiftUI

@main
struct WWWeebApp: App {
    @Environment(\.scenePhase)
    private var scenePhase

    let settings: Settings
    let library: Library

    init() {
        settings = Settings.load()
        library = Library.load()
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                LibraryView()
                    .tabItem {
                        Label("Library", systemImage: "book.pages")
                    }
                BrowseView()
                    .tabItem {
                        Label("Browse", systemImage: "safari")
                    }
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
            .modifier(SettingsEnvironmentModifier(settings: settings))
            .modifier(LibraryEnvironmentModifier(library: library))
            .preferredColorScheme(settings.appearanceId == 2 ? .dark : settings.appearanceId == 1 ? .light : nil)
            .onChange(of: scenePhase) { _, newScenePhase in
                if newScenePhase == .background {
                    Settings.save(settings)
                    Library.save(library)
                }
            }
        }
    }
}
