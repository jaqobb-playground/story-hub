import Kingfisher
import SwiftData
import SwiftUI
import OSLog

struct BrowseView: View {
    @Environment(\.library)
    var library

    @State
    var novelsSearchText = ""
    @State
    var novelPreviews: [NovelPreview] = []
    @State
    var midNovelSearch = false

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
                    ForEach(novelPreviews, id: \.path) { novelPreview in
                        NovelPreviewCell(novelPreview: novelPreview, novel: library.getNovel(novelPath: novelPreview.path))
                    }
                }
            }
            .navigationTitle("Browse")
        }
    }

    private func performNovelSearch() {
        if midNovelSearch {
            return
        }
        
        if !novelsSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Logger.library.info("Performing novel search...")
            
            midNovelSearch = true
            
            novelPreviews = []
            
            Task.init {
                for sourceType in SourceType.allCases {
                    do {
                        let novelPreviews = try await sourceType.source.fetchNovels(searchTerm: novelsSearchText)
                        for novelPreview in novelPreviews {
                            Logger.library.info("Novel '\(novelPreview.title)' from '\(novelPreview.sourceType.source.name)' found to be matching the search criteria.")
                            
                            self.novelPreviews.append(novelPreview)
                        }
                    } catch {
                        Logger.library.warning("Failed to fetch novel previews from '\(sourceType.source.name)': \(error.localizedDescription)")
                        
                        AlertUtils.showAlert(title: "Failed to fetch novel previews from '\(sourceType.source.name)'", message: error.localizedDescription)
                    }
                }
                
                midNovelSearch = false
            }
        }
    }
}

private struct NovelPreviewCell: View {
    @Environment(\.library)
    var library

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
        }
        .buttonStyle(PlainButtonStyle())
    }
}
