import SwiftData
import SwiftUI

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
