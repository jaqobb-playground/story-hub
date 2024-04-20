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
                    TextField("Enter novel title...", text: $novelsSearchText, onCommit: { performNovelsSearch() })
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
                for sourceType in SourceType.allCases {
                    do {
                        let novelPreviews = try await sourceType.source.fetchNovels(searchTerm: novelsSearchText)
                        for novelPreview in novelPreviews {
                            self.novelPreviews.append(novelPreview)
                        }
                    } catch {
                        AlertUtils.showAlert(title: "Failed to fetch novel previews from '\(sourceType.source.name)'", message: error.localizedDescription)
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
        }
        .buttonStyle(PlainButtonStyle())
    }
}
