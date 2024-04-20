import OSLog
import SwiftUI

struct NovelChapterView: View {
    @Environment(\.presentationMode)
    private var presentationMode

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
                    AlertUtils.showAlert(title: "Failed to fetch novel's '\(novel.title)' chapter '\(novelChapter.title)' content", message: error.localizedDescription) { _ in
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
