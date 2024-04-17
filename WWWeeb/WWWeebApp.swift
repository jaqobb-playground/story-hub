import SwiftData
import SwiftUI

// TODO: Cache chapter contents?
// TODO: Can clear the cache for that chapter after a while or when or upon novel update.
@main
struct WWWeebApp: App {
    @StateObject
    var libraryStore = LibraryStore()

    var body: some Scene {
        WindowGroup {
            TabView {
                LibraryView()
                    .tabItem {
                        Label("Library", systemImage: "book.pages")
                    }
                    .environmentObject(libraryStore)
                BrowseView()
                    .tabItem {
                        Label("Browse", systemImage: "safari")
                    }
                    .environmentObject(libraryStore)
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .environmentObject(libraryStore)
            }
        }
    }
}
