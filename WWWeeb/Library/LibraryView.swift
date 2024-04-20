import Kingfisher
import OSLog
import SwiftData
import SwiftUI

struct LibraryView: View {
    @Environment(\.library)
    private var library

    @State
    var novelsSearchInProgress = false
    @State
    var novelsSearchText: String = ""
    @State
    var novels: [Novel] = []

    var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                HStack {
                    TextField("Enter novel title...", text: $novelsSearchText, onCommit: { performNovelsSearch() })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    HStack(spacing: 12) {
                        Button(action: { performNovelsSearch() }) {
                            Image(systemName: "magnifyingglass")
                        }

                        Menu {
                            Section(header: Text("Include novels")) {
                                ForEach(Novel.Category.allCases, id: \.id) { novelCategory in
                                    Button {
                                        if !library.novelsCategoryIncludes.contains(novelCategory) {
                                            library.novelsCategoryIncludes.insert(novelCategory)
                                        } else {
                                            library.novelsCategoryIncludes.remove(novelCategory)
                                        }

                                        performNovelsSearch()
                                    } label: {
                                        if library.novelsCategoryIncludes.contains(novelCategory) {
                                            Label(novelCategory.name, systemImage: "checkmark")
                                        } else {
                                            Text(novelCategory.name)
                                        }
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease")
                        }

                        Menu {
                            Section(header: Text("Sort novels by")) {
                                ForEach(Library.NovelsSortingMode.allCases, id: \.id) { novelsSortingMode in
                                    if library.novelsSortingMode.id == novelsSortingMode.id {
                                        Label(novelsSortingMode.name, systemImage: "checkmark")
                                    } else {
                                        Button {
                                            library.novelsSortingMode = novelsSortingMode

                                            performNovelsSearch()
                                        } label: {
                                            Text(novelsSortingMode.name)
                                        }
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }
                    }
                    .padding(.trailing)
                }
                .padding(.leading)

                Spacer()

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 2) {
                    ForEach(novels, id: \.path) { novel in
                        NovelCell(novel: novel, performNovelsSearch: performNovelsSearch)
                    }
                }
            }
            .navigationTitle("Library")
            .refreshable {
                for novel in novels {
                    await novel.update()
                }
            }
            .onAppear {
                // This should ensure the first search is done after the library is actually loaded.
                Task.init {
                    performNovelsSearch()
                }
            }
        }
    }

    private func performNovelsSearch() {
        if novelsSearchInProgress {
            return
        }

        novelsSearchInProgress = true
        novels = []

        for novel in library.novels {
            if !novelsSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if !novel.title.lowercased().contains(novelsSearchText.lowercased()) {
                    continue
                }
            }

            if !library.novelsCategoryIncludes.contains(novel.category) {
                continue
            }

            novels.append(novel)
        }

        novels.sort(by: library.novelsSortingMode.comparator())
        novelsSearchInProgress = false
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
    
    let performNovelsSearch: () -> Void

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
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .contextMenu {
                Section {
                    Button {
                        var novelChaptersReadChanged = false
                        for novelChapter in novel.chapters {
                            let (inserted, _) = novel.chaptersRead.insert(novelChapter.path)
                            if inserted {
                                novelChaptersReadChanged = true
                            }
                        }

                        if novelChaptersReadChanged {
                            performNovelsSearch()
                        }
                    } label: {
                        Label("Mark as read", systemImage: "checkmark")
                    }

                    Button(role: .destructive) {
                        var novelChaptersReadChanged = false
                        for novelChapter in novel.chapters {
                            let removed = novel.chaptersRead.remove(novelChapter.path) != nil
                            if removed {
                                novelChaptersReadChanged = true
                            }
                        }

                        if novelChaptersReadChanged {
                            performNovelsSearch()
                        }
                    } label: {
                        Label("Mark as not read", systemImage: "xmark")
                    }
                }

                Section {
                    Menu {
                        ForEach(Novel.Category.allCases, id: \.id) { novelCategory in
                            if novel.category.id == novelCategory.id {
                                Label(novelCategory.name, systemImage: "checkmark")
                            } else {
                                Button {
                                    novel.category = novelCategory

                                    performNovelsSearch()
                                } label: {
                                    Text(novelCategory.name)
                                }
                            }
                        }
                    } label: {
                        Label("Change category to", systemImage: "book")
                    }

                    Button {
                        Task.init {
                            await novel.update()
                            
                            performNovelsSearch()
                        }
                    } label: {
                        Label("Update", systemImage: "arrow.clockwise")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        library.novels.remove(novel)
                        
                        performNovelsSearch()
                    } label: {
                        Label("Remove from library", systemImage: "trash")
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
