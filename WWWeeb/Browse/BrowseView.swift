import Kingfisher
import SwiftUI

struct BrowseView: View {
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass
    @Environment(\.settings)
    private var settings
    @Environment(\.library)
    private var library

    @State
    var settingsSheetVisible = false
    @State
    var searchInProgress = false
    @State
    var searchBarFocused = false
    @State
    var searchText = ""
    @State
    var novelPreviews: [NovelPreview] = []

    var body: some View {
        ScrollView(.vertical) {
            let novelPreviewChunks = novelPreviews.chunked(into: horizontalSizeClass == .compact ? 2 : 4)
            ForEach(novelPreviewChunks, id: \.self) { novelPreviews in
                VStack {
                    HStack(spacing: 12) {
                        ForEach(novelPreviews, id: \.path) { novelPreview in
                            NovelPreviewCell(novelPreview: novelPreview, novel: library.novels[novelPreview.path])
                        }

                        let missingNovelPreviews = (horizontalSizeClass == .compact ? 2 : 4) - novelPreviews.count
                        if missingNovelPreviews > 0 {
                            ForEach(0 ..< missingNovelPreviews, id: \.self) { _ in
                                Spacer()
                                    .scaledToFit()
                                    .cornerRadius(10)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
        }
        .navigationTitle("Browse")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, isPresented: $searchBarFocused, placement: .navigationBarDrawer(displayMode: .always))
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .onSubmit(of: .search) {
            performSearch()
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

    private func performSearch() {
        if searchInProgress {
            return
        }

        searchBarFocused = false
        novelPreviews = []

        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return
        }

        searchInProgress = true

        Task.init {
            for novelProvider in settings.novelProviders {
                do {
                    novelPreviews.append(contentsOf: try await novelProvider.implementation.fetchNovels(searchTerm: searchText))
                } catch {
                    AlertUtils.showAlert(title: "Failed to Fetch Novel Previews from '\(novelProvider.implementation.details.name)'", message: error.localizedDescription)
                }
            }

            searchInProgress = false
        }
    }
}
