import SwiftData
import SwiftUI

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
