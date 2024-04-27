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
            NavigationStack {
                LibraryView()
            }
            .modifier(SettingsEnvironmentModifier(settings: settings))
            .modifier(LibraryEnvironmentModifier(library: library))
            .onChange(of: scenePhase) { _, newScenePhase in
                if newScenePhase == .background {
                    Task {
                        Settings.save(settings)
                        Library.save(library)
                    }
                }
            }
        }
    }
}
