import SwiftData
import SwiftUI

@main
struct WWWeebApp: App {
    @Environment(\.scenePhase)
    private var scenePhase

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
            .onChange(of: scenePhase) { _, newScenePhase in
                switch newScenePhase {
                    case .background:
                        library.save()
                    case .inactive:
                        break
                    case .active:
                        break
                    @unknown
                    default:
                        break
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                library.save()
            }
        }
    }
}
