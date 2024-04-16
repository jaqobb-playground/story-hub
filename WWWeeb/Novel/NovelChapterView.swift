import SwiftUI

struct NovelChapterView: View {
    @Environment(\.presentationMode)
    var presentationMode
    @EnvironmentObject
    var libraryStore: LibraryStore

    let novel: Novel
    let novelChapter: NovelChapter
    @State
    var novelChapterContent: NovelChapterContent?

    var body: some View {
        ScrollView(.vertical) {
            if let novelChapterContent = novelChapterContent {
                ForEach(novelChapterContent.contents, id: \.self) { content in
                    Text(content)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle(novelChapterContent?.title ?? "Loading...")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task.init {
                do {
                    novelChapterContent = try await novel.sourceType.source.parseNovelChapter(novelChapterPath: novelChapter.path)
                } catch {
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Could not fetch chapter content", message: error.localizedDescription, preferredStyle: .alert)
                        let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                            presentationMode.wrappedValue.dismiss()
                        }
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
        }
    }
}
