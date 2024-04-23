import OSLog
import SwiftUI

struct NovelChapterView: View {
    @Environment(\.presentationMode)
    private var presentationMode
    @Environment(\.settings)
    private var settings

    let novel: Novel
    @State
    var novelChapter: NovelChapter
    @State
    var novelChapterContent: [String]?
    var novelChapterIndex: Int {
        novelChapter.number - 1
    }

    var novelFirstChapterNumber: Int {
        novel.chapters.first?.number ?? -1
    }

    var novelLastChapterNumber: Int {
        novel.chapters.last?.number ?? -1
    }

    init(novel: Novel, novelChapter: NovelChapter) {
        self.novel = novel
        _novelChapter = State(initialValue: novelChapter)
    }

    var body: some View {
        ScrollViewReader { reader in
            ScrollView(.vertical) {
                if let novelChapterContent = novelChapterContent {
                    LazyVStack {
                        ForEach(novelChapterContent.indices, id: \.self) { index in
                            Text(novelChapterContent[index])
                                .font(.system(size: settings.novelChapterFontSize))
                                .padding(.horizontal, settings.novelChapterHorizontalPadding)
                                .padding(.vertical, settings.novelChapterVerticalPadding)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(index)
                        }
                        
                        HStack {
                            if novelChapter.number > novelFirstChapterNumber {
                                Button {
                                    reader.scrollTo(0, anchor: .top)

                                    if settings.markNovelChapterAsReadWhenSwitching {
                                        novel.chaptersRead.insert(novelChapter.path)
                                    }
                                    novelChapter = novel.chapters[novelChapterIndex - 1]

                                    fetchNovelChapterContent()
                                } label: {
                                    Image(systemName: "arrow.backward")
                                    Text("Previous Chapter")
                                }
                            } else {
                                Spacer()
                            }

                            Spacer()

                            if novelChapter.number < novelLastChapterNumber {
                                Button {
                                    reader.scrollTo(0, anchor: .top)

                                    if settings.markNovelChapterAsReadWhenSwitching {
                                        novel.chaptersRead.insert(novelChapter.path)
                                    }
                                    novelChapter = novel.chapters[novelChapterIndex + 1]

                                    fetchNovelChapterContent()
                                } label: {
                                    Text("Next Chapter")
                                    Image(systemName: "arrow.forward")
                                }
                            } else {
                                Spacer()
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical)
                        .onAppear {
                            // With LazyVStack, when this appears it means we've reached the bottom (== chapter read).
                            if settings.markNovelChapterAsReadWhenFinished {
                                novel.chaptersRead.insert(novelChapter.path)
                            }
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(novelChapter.title)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                fetchNovelChapterContent()
            }
        }
    }

    private func fetchNovelChapterContent() {
        if let novelChapterContent = novelChapter.content {
            self.novelChapterContent = novelChapterContent
        } else {
            Task.init {
                do {
                    novelChapterContent = try await novel.provider.implementation.parseNovelChapter(path: novelChapter.path)
                } catch {
                    AlertUtils.showAlert(title: "Failed to Fetch Novel Chapter '\(novelChapter.title)' Content", message: error.localizedDescription) { _ in
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
