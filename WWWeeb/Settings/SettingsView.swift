import SwiftUI

struct SettingsView: View {
    @EnvironmentObject
    var libraryStore: LibraryStore
    
    var body: some View {
        NavigationView {
            VStack {
            }
            .navigationTitle("Settings")
        }
    }
}
