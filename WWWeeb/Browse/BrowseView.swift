import Kingfisher
import SwiftUI

struct BrowseView: View {
    @Environment(\.verticalSizeClass)
    private var verticalSizeClass
    @Environment(\.settings)
    private var settings
    @Environment(\.library)
    private var library

    @State
    var settingsSheetVisible = false
    @State
    var novelSearchInProgress = false
    @State
    var novelSearchBarFocused = false
    @State
    var novelSearchText = ""
    @State
    var novelPreviews: [NovelPreview] = []

    var body: some View {
        ScrollView(.vertical) {
            let columns = Array(repeating: GridItem(.flexible()), count: verticalSizeClass == .regular ? 2 : 4)
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(novelPreviews, id: \.path) { novelPreview in
                    NovelPreviewCell(novelPreview: novelPreview, novel: library.novels[novelPreview.path])
                }
            }
        }
        .navigationTitle("Browse")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $novelSearchText, isPresented: $novelSearchBarFocused, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search title...")
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .onSubmit(of: .search) {
            performNovelSearch()
        }
        .toolbar {
            ToolbarItem(id: "Settings", placement: .topBarTrailing) {
                Button {
                    settingsSheetVisible = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
            }
        }
        .sheet(isPresented: $settingsSheetVisible) {
            BrowseSettingsSheet(settingsSheetVisible: $settingsSheetVisible)
        }
    }

    private func performNovelSearch() {
        if novelSearchInProgress {
            return
        }

        novelSearchBarFocused = false
        novelPreviews = []
        if novelSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return
        }

        novelSearchInProgress = true

        Task.init {
            for novelProvider in settings.novelProviders {
                do {
                    novelPreviews.append(contentsOf: try await novelProvider.implementation.fetchNovels(searchTerm: novelSearchText))
                } catch {
                    AlertUtils.showAlert(title: "Failed to Fetch Novel Previews from '\(novelProvider.implementation.details.name)'", message: error.localizedDescription)
                }
            }

            novelSearchInProgress = false
        }
    }
}
