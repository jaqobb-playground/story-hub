import Kingfisher
import SwiftData
import SwiftUI
import OSLog

struct BrowseView: View {
    @Environment(\.library)
    private var library

    @State
    var novelsSearchInProgress = false
    @State
    var novelsSearchText = ""
    @State
    var novelPreviews: [NovelPreview] = []

    var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                HStack {
                    TextField("Enter title...", text: $novelsSearchText, onCommit: { performNovelsSearch() })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.leading)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    Button(action: { performNovelsSearch() }) {
                        Image(systemName: "magnifyingglass")
                    }
                    .padding(.trailing)
                }

                Spacer()

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 2) {
                    ForEach(novelPreviews, id: \.path) { novelPreview in
                        NovelPreviewCell(novelPreview: novelPreview, novel: library.novels[novelPreview.path])
                    }
                }
            }
            .navigationTitle("Browse")
        }
    }

    private func performNovelsSearch() {
        if novelsSearchInProgress {
            return
        }
        
        if !novelsSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            novelsSearchInProgress = true
            novelPreviews = []
            
            Task.init {
                for novelSourceType in NovelSourceType.allCases {
                    do {
                        self.novelPreviews.append(contentsOf: try await novelSourceType.source.fetchNovels(searchTerm: novelsSearchText))
                    } catch {
                        AlertUtils.showAlert(title: "Failed to fetch novel previews from '\(novelSourceType.source.name)'", message: error.localizedDescription)
                    }
                }
                
                novelsSearchInProgress = false
            }
        }
    }
}

private struct NovelPreviewCell: View {
    @Environment(\.library)
    private var library

    let novelPreview: NovelPreview
    let novel: Novel?

    var body: some View {
        NavigationLink {
            if let novel = novel {
                NovelView(novel: novel)
            } else {
                NovelView(novelPreview: novelPreview)
            }
        } label: {
            VStack(spacing: 4) {
                KFImage(URL(string: novelPreview.coverURL))
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text(novelPreview.title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .contextMenu {
                Section {
                    if let novel = novel {
                        Button(role: .destructive) {
                            library.novels.remove(novel)
                        } label: {
                            Label("Remove from Library", systemImage: "bookmark.slash")
                        }
                    } else {
                        Button {
                            Task.init {
                                do {
                                    library.novels.insert(try await novelPreview.sourceType.source.parseNovel(novelPath: novelPreview.path))
                                } catch {
                                    AlertUtils.showAlert(title: "Failed to fetch novel '\(novelPreview.title)'", message: error.localizedDescription)
                                }
                            }
                        } label: {
                            Label("Add to Library", systemImage: "bookmark")
                        }
                        
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
