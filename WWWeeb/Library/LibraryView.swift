import Kingfisher
import OSLog
import SwiftData
import SwiftUI

struct LibraryView: View {
    @Environment(\.verticalSizeClass)
    private var verticalSizeClass
    @Environment(\.library)
    private var library

    @State
    var novelsSearchText: String = ""
    var novels: [Novel] {
        var novels: [Novel] = []

        for novel in library.novels {
            if !novelsSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if !novel.title.lowercased().contains(novelsSearchText.lowercased()) {
                    continue
                }
            }

            if !library.novelFilters.contains(where: { $0.matches(novel: novel) }) {
                continue
            }

            novels.append(novel)
        }

        novels.sort(by: library.novelSortingMode.comparator())
        return novels
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                TextField("Enter title...", text: $novelsSearchText)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(.horizontal)

                HStack(spacing: 16) {
                    Menu {
                        Section(header: Text("Novels")) {
                            ForEach(Novel.Filter.allCases) { novelFilter in
                                Button {
                                    if !library.novelFilters.contains(novelFilter) {
                                        library.novelFilters.insert(novelFilter)
                                    } else {
                                        library.novelFilters.remove(novelFilter)
                                    }
                                } label: {
                                    if library.novelFilters.contains(novelFilter) {
                                        Label(novelFilter.name, systemImage: "checkmark")
                                    } else {
                                        Text(novelFilter.name)
                                    }
                                }
                            }
                        }
                    } label: {
                        Label("Filters", systemImage: "line.3.horizontal.decrease")
                    }

                    Menu {
                        Section(header: Text("Novels")) {
                            ForEach(Novel.SortingMode.allCases) { novelSortingMode in
                                if library.novelSortingMode == novelSortingMode {
                                    Label(novelSortingMode.name, systemImage: "checkmark")
                                } else {
                                    Button {
                                        library.novelSortingMode = novelSortingMode
                                    } label: {
                                        Text(novelSortingMode.name)
                                    }
                                }
                            }
                        }
                    } label: {
                        Label("Sort By", systemImage: "arrow.up.arrow.down")
                    }

                    Spacer()
                }
                .padding(.horizontal)

                Spacer()

                let columns = Array(repeating: GridItem(.flexible()), count: verticalSizeClass == .regular ? 2 : 4)
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(novels, id: \.path) { novel in
                        NovelCell(novel: novel)
                    }
                }
            }
            .navigationTitle("Library")
            .refreshable {
                await Task {
                    for novel in library.novels.filter({ $0.category != .completed }) {
                        await novel.update()
                    }
                }
                .value
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
}

private struct NovelCell: View {
    @Environment(\.library)
    private var library

    let novel: Novel

    var novelChaptersReadString: String {
        String(novel.chaptersRead.count).trimmingCharacters(in: .whitespaces)
    }

    var novelChaptersTotalString: String {
        String(novel.chapters.count).trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        NavigationLink {
            NovelView(novel: novel)
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    KFImage(URL(string: novel.coverURL))
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(10)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    if novel.chaptersRead.count < novel.chapters.count {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 6)
                    }
                }

                Text(novel.title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text("\(novelChaptersReadString)/\(novelChaptersTotalString)".trimmingCharacters(in: .whitespaces))
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(.horizontal)
            .padding(.vertical)
            .contextMenu {
                Section {
                    Button {
                        novel.chaptersRead.formUnion(novel.chapters.map({ $0.path }))
                    } label: {
                        Label("Mark as Read", systemImage: "checkmark")
                    }

                    Button(role: .destructive) {
                        novel.chaptersRead.subtract(novel.chapters.map({ $0.path }))
                    } label: {
                        Label("Unmark as Read", systemImage: "xmark")
                    }
                }

                Section {
                    Menu {
                        ForEach(Novel.Category.allCases) { novelCategory in
                            if novel.category == novelCategory {
                                Label(novelCategory.name, systemImage: "checkmark")
                            } else {
                                Button {
                                    novel.category = novelCategory
                                } label: {
                                    Text(novelCategory.name)
                                }
                            }
                        }
                    } label: {
                        Label("Change Category To", systemImage: "book")
                    }

                    Button {
                        Task.init {
                            await novel.update()
                        }
                    } label: {
                        Label("Update", systemImage: "arrow.clockwise")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        for novelChapter in novel.chapters {
                            novelChapter.content = nil
                        }
                    } label: {
                        Label("Remove All Downloads", systemImage: "trash")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        library.novels.remove(novel)
                    } label: {
                        Label("Remove from Library", systemImage: "bookmark.slash")
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
