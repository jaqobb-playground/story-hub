import Kingfisher
import OSLog
import SwiftData
import SwiftUI

struct LibraryView: View {
    @Environment(\.verticalSizeClass)
    private var verticalSizeClass
    @Environment(\.settings)
    private var settings
    @Environment(\.library)
    private var library

    @State
    var settingsSheetVisible = false
    @State
    var searchText: String = ""
    var novels: [Novel] {
        var novels: [Novel] = []

        for novel in library.novels {
            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if !novel.title.lowercased().contains(searchText.lowercased()) {
                    continue
                }
            }

            if !settings.novelFilters.contains(where: { $0.matches(novel: novel) }) {
                continue
            }

            novels.append(novel)
        }

        novels.sort(by: settings.novelSortingMode.comparator())
        return novels
    }

    var body: some View {
        ScrollView(.vertical) {
            let novelChunks = novels.chunked(into: verticalSizeClass == .regular ? 2 : 4)
            ForEach(novelChunks, id: \.self) { novels in
                VStack {
                    HStack(spacing: 12) {
                        ForEach(novels, id: \.path) { novel in
                            NovelCell(novel: novel)
                        }

                        let missingNovels = (verticalSizeClass == .regular ? 2 : 4) - novels.count
                        if missingNovels > 0 {
                            ForEach(0 ..< missingNovels, id: \.self) { _ in
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
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .toolbar {
            ToolbarItem(id: "Add", placement: .topBarTrailing) {
                NavigationLink {
                    BrowseView()
                } label: {
                    Image(systemName: "plus")
                }
            }

            ToolbarItem(id: "Setting", placement: .topBarTrailing) {
                Button {
                    settingsSheetVisible = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
            }
        }
        .sheet(isPresented: $settingsSheetVisible) {
            LibrarySettingsSheet(settingsSheetVisible: $settingsSheetVisible)
        }
        .refreshable {
            await Task {
                for novel in library.novels.filter({ $0.category != .completed }) {
                    await novel.update()
                }
            }
            .value
        }
    }
}
