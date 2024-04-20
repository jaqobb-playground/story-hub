import SwiftData
import SwiftUI

@main
struct WWWeebApp: App {
    @Environment(\.scenePhase)
    private var scenePhase

    let library: Library

    init() {
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
            .modifier(LibraryEnvironmentModifier(library: library))
            .onChange(of: scenePhase) { _, newScenePhase in
                if newScenePhase == .background {
                    Library.save(library)
                }
            }
        }
    }
}
