import Kingfisher
import SwiftData
import SwiftUI

struct LibraryView: View {
    @EnvironmentObject
    var libraryStore: LibraryStore

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
                    ForEach(Array(libraryStore.library.novels), id: \.path) { novel in
                        NovelCell(novel: novel)
                            .environmentObject(libraryStore)
                    }
                }
            }
            .navigationTitle("Library")
            .refreshable {
                Task.init {
                    for novel in libraryStore.library.novels {
                        do {
                            let novelUpdated = try await novel.sourceType.source.parseNovel(novelPath: novel.path)

                            libraryStore.library.novels.remove(novel)
                            libraryStore.library.novels.insert(novelUpdated)
                        } catch {
                            DispatchQueue.main.async {
                                let alert = UIAlertController(title: "Could not update novel \(novel.title)", message: error.localizedDescription, preferredStyle: .alert)
                                let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                                alert.addAction(alertAction)

                                if let window = UIApplication.shared.connectedScenes
                                    .filter({ $0.activationState == .foregroundActive })
                                    .compactMap({ $0 as? UIWindowScene })
                                    .first?.windows
                                    .first {
                                    window.rootViewController?.present(alert, animated: true, completion: nil)
                                }
                            }
                        }
                    }

                    libraryStore.saveLibrary()
                }
            }
        }
    }

    private func performNovelSearch() {
        if !novelsSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("Performing search...")
        }
    }
}

private struct NovelCell: View {
    @EnvironmentObject
    var libraryStore: LibraryStore

    let novel: Novel

    var novelChaptersRead: Int {
        libraryStore.library.getNovelChaptersMarkedAsRead(novel: novel)
    }

    var novelChaptersReadString: String {
        String(novelChaptersRead).trimmingCharacters(in: .whitespaces)
    }

    var novelChaptersTotalString: String {
        String(novel.chapters.count).trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        NavigationLink {
            NovelView(novel: novel)
                .environmentObject(libraryStore)
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    KFImage(URL(string: novel.coverURL))
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(10)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    if novelChaptersRead < novel.chapters.count {
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
                        if novelChaptersRead >= novel.chapters.count {
                            return
                        }

                        for novelChapter in novel.chapters {
                            libraryStore.library.markNovelChapterAsRead(novel: novel, novelChapter: novelChapter)
                        }

                        libraryStore.saveLibrary()
                    } label: {
                        Label("Mark as read", systemImage: "checkmark")
                    }

                    Button(role: .destructive) {
                        if novelChaptersRead <= 0 {
                            return
                        }

                        for novelChapter in novel.chapters {
                            libraryStore.library.unmarkNovelChapterAsRead(novel: novel, novelChapter: novelChapter)
                        }

                        libraryStore.saveLibrary()
                    } label: {
                        Label("Mark as not read", systemImage: "xmark")
                    }
                }

                // TODO: Implement
                Section {
                    Menu {
                        Text("Reading")
                        Text("Completed")
                    } label: {
                        Label("Change category to", systemImage: "arrow.up.arrow.down")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        libraryStore.library.novels.remove(novel)
                        libraryStore.saveLibrary()
                    } label: {
                        Label("Remove from library", systemImage: "trash")
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
