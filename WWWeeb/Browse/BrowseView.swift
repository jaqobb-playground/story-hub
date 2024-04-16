import Kingfisher
import SwiftData
import SwiftUI

struct BrowseView: View {
    @EnvironmentObject
    var libraryStore: LibraryStore

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
                        NovelPreviewCell(novelPreview: novelPreview, novel: libraryStore.library.getNovel(novelPath: novelPreview.path))
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
        
        novelPreviews = []
        if !novelsSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            midNovelSearch = true
            
            Task.init {
                for sourceType in SourceType.allCases {
                    do {
                        let novelPreviews = try await sourceType.source.fetchNovels(searchTerm: novelsSearchText)
                        for novelPreview in novelPreviews {
                            self.novelPreviews.append(novelPreview)
                        }
                    } catch {
                        DispatchQueue.main.async {
                            let alert = UIAlertController(title: "Could not fetch novel previews from \(sourceType.source.name)", message: error.localizedDescription, preferredStyle: .alert)
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
                
                midNovelSearch = false
            }
        }
    }
}

private struct NovelPreviewCell: View {
    @EnvironmentObject
    var libraryStore: LibraryStore

    let novelPreview: NovelPreview
    let novel: Novel?

    var body: some View {
        NavigationLink {
            if let novel = novel {
                NovelView(novel: novel)
                    .environmentObject(libraryStore)
            } else {
                NovelView(novelPreview: novelPreview)
                    .environmentObject(libraryStore)
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
