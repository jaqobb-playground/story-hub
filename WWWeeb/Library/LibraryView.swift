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
    var novelSearchText: String = ""
    var novels: [Novel] {
        var novels: [Novel] = []

        for novel in library.novels {
            if !novelSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if !novel.title.lowercased().contains(novelSearchText.lowercased()) {
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
            let columns = Array(repeating: GridItem(.flexible()), count: verticalSizeClass == .regular ? 2 : 4)
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(novels, id: \.path) { novel in
                    NovelCell(novel: novel)
                }
            }
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $novelSearchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search title...")
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
