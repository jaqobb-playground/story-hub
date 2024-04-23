import Kingfisher
import OSLog
import SwiftData
import SwiftUI

struct BrowseView: View {
    @Environment(\.verticalSizeClass)
    var verticalSizeClass
    @Environment(\.settings)
    private var settings
    @Environment(\.library)
    private var library

    @State
    var novelsSearchInProgress = false
    @State
    var novelsSearchText = ""
    @State
    var novelPreviews: [NovelPreview] = []

    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                TextField("Enter title...", text: $novelsSearchText, onCommit: { performNovelsSearch() })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(.horizontal)

                Spacer()

                let columns = Array(repeating: GridItem(.flexible()), count: verticalSizeClass == .regular ? 2 : 4)
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(novelPreviews, id: \.path) { novelPreview in
                        NovelPreviewCell(novelPreview: novelPreview, novel: library.novels[novelPreview.path])
                    }
                }
            }
            .navigationTitle("Browse")
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
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
                for novelProvider in settings.novelProviders {
                    do {
                        novelPreviews.append(contentsOf: try await novelProvider.implementation.fetchNovels(searchTerm: novelsSearchText))
                    } catch {
                        AlertUtils.showAlert(title: "Failed to Fetch Novel Previews from '\(novelProvider.implementation.details.name)'", message: error.localizedDescription)
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
            .padding(.horizontal)
            .padding(.vertical)
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
                                    library.novels.insert(try await novelPreview.provider.implementation.parseNovel(path: novelPreview.path))
                                } catch {
                                    AlertUtils.showAlert(title: "Failed to Fetch Novel '\(novelPreview.title)'", message: error.localizedDescription)
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
