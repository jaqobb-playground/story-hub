import SwiftData
import SwiftUI

// TODO: Cache chapter contents?
// TODO: Can clear the cache for that chapter after a while or when or upon novel update.
@main
struct WWWeebApp: App {
    let library: Library

    init() {
        library = Library()
        library.load()
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
        }
    }
}
