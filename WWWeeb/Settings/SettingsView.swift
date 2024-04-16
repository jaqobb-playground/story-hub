import SwiftUI

struct SettingsView: View {
    @EnvironmentObject
    var libraryStore: LibraryStore

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("About")) {
                    LabeledContent {
                        Text(getAppVersion())
                    } label: {
                        Text("Version")
                    }
                    
                    LabeledContent {
                        Text(getAppBuild())
                    } label: {
                        Text("Build")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func getAppVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "Unknown"
    }
    
    private func getAppBuild() -> String {
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return build
        }
        return "Unknown"
    }
}
