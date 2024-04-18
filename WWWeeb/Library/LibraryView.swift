import Kingfisher
import OSLog
import SwiftData
import SwiftUI

struct LibraryView: View {
    @Environment(\.library)
    var library

    @State
    var novelsSearchText: String = ""

    var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                HStack {
                    TextField("Enter novel title...", text: $novelsSearchText, onCommit: { performNovelSearch() })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.leading)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    Button(action: { performNovelSearch() }) {
                        Image(systemName: "magnifyingglass")
                    }
                    .padding(.trailing)
                }

                Spacer()

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 2) {
                    ForEach(Array(library.novels), id: \.path) { novel in
                        NovelCell(novel: novel)
                    }
                }
            }
            .navigationTitle("Library")
            .refreshable {
                Task.init {
                    Logger.library.info("Updating novels...")

                    for novel in library.novels {
                        try await novel.update()
                    }

                    library.save()
                }
            }
        }
    }

    private func performNovelSearch() {
        if !novelsSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // TODO: Actually do it.
            Logger.library.info("Performing novel search...")
        }
    }
}

private struct NovelCell: View {
    @Environment(\.library)
    var library

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
                            library.save()
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
                            library.save()
                        }
                    } label: {
                        Label("Mark as not read", systemImage: "xmark")
                    }
                }

                Section {
                    // TODO: Implement
                    Menu {
                        Text("Reading")
                        Text("Completed")
                    } label: {
                        Label("Change category to", systemImage: "arrow.up.arrow.down")
                    }
                    
                    Button {
                        Task.init {
                            try await novel.update()

                            library.save()
                        }
                    } label: {
                        Label("Update", systemImage: "arrow.clockwise")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        Logger.library.info("Removing novel '\(novel.title)' from the library...")

                        library.novels.remove(novel)
                        library.save()
                    } label: {
                        Label("Remove from library", systemImage: "trash")
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
