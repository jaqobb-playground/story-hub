import Kingfisher
import OSLog
import SwiftData
import SwiftUI

struct NovelView: View {
    @Environment(\.presentationMode)
    var presentationMode
    @Environment(\.library)
    var library

    var novel: Novel?
    var novelPreview: NovelPreview?

    @State
    var novelUsed: Novel?

    init(novel: Novel) {
        self.novel = novel
    }

    init(novelPreview: NovelPreview) {
        self.novelPreview = novelPreview
    }

    var body: some View {
        Form {
            if let novel = novelUsed {
                NovelInformation(novel)
            } else {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowInsets(.init())
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Novel")
        .onAppear {
            if let novel = novel {
                novelUsed = novel
            } else {
                if let novelPreview = novelPreview {
                    Task.init {
                        Logger.library.info("Fetching novel '\(novelPreview.title)'...")

                        do {
                            novelUsed = try await novelPreview.sourceType.source.parseNovel(novelPath: novelPreview.path)
                        } catch {
                            Logger.library.warning("Failed to fetch novel '\(novelPreview.title)': \(error.localizedDescription)")

                            AlertUtils.showAlert(title: "Failed to fetch novel '\(novelPreview.title)'", message: error.localizedDescription) { _ in
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct NovelInformation: View {
    @Environment(\.library)
    var library

    let novel: Novel

    init(_ novel: Novel) {
        self.novel = novel
    }

    var body: some View {
        Section {
            HStack {
                Spacer()

                VStack(alignment: .center, spacing: 2) {
                    KFImage(URL(string: novel.coverURL))
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(10)
                        .frame(maxWidth: 200, maxHeight: 300)

                    Text(novel.title)
                        .font(.title)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .listRowInsets(.init())
            .listRowBackground(Color.clear)
        }

        Section(header: Text("Information")) {
            NavigationLink {
                List(novel.authors, id: \.self) { author in
                    Text(author)
                }
            } label: {
                Label("Authors", systemImage: "person")
            }

            NavigationLink {
                List(novel.genres, id: \.self) { genre in
                    Text(genre)
                }
            } label: {
                Label("Genres", systemImage: "list.bullet")
            }

            NavigationLink {
                List(novel.summary, id: \.self) { summaryContent in
                    Text(summaryContent)
                }
            } label: {
                Label("Summary", systemImage: "book")
            }

            LabeledContent {
                Text(novel.status.capitalized)
            } label: {
                Label("Status", systemImage: "clock")
            }
        }

        Section(header: Text("Chapters")) {
            let novelChapterChunked = novel.splitChaptersIntoChunks(chunkSize: 100)

            List(novelChapterChunked.reversed(), id: \.self) { novelChaptersChunk in
                NovelChaptersChunk(novel: novel, novelChaptersChunk: novelChaptersChunk)
            }
        }

        Section {
            if library.getNovel(novelPath: novel.path) == nil {
                Button("Add to library") {
                    Logger.library.info("Adding novel '\(novel.title)' to the library...")

                    library.novels.insert(novel)
                    library.save()
                }
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Button("Remove from library") {
                    Logger.library.info("Removing novel '\(novel.title)' from the library...")

                    library.novels.remove(novel)
                    library.save()
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

private struct NovelChaptersChunk: View {
    @Environment(\.library)
    var library

    let novel: Novel
    let novelChaptersChunk: [NovelChapter]

    private var firstChapterNumber: String {
        String(novelChaptersChunk.first!.number).trimmingCharacters(in: .whitespaces)
    }

    private var lastChapterNumber: String {
        String(novelChaptersChunk.last!.number).trimmingCharacters(in: .whitespaces)
    }

    private var allChaptersRead: Bool {
        for novelChapter in novelChaptersChunk {
            if !library.isNovelChapterMarkedAsRead(novel: novel, novelChapter: novelChapter) {
                return false
            }
        }
        return true
    }

    var body: some View {
        NavigationLink {
            NovelChaptersChunkDetails(
                firstChapterNumber: firstChapterNumber,
                lastChapterNumber: lastChapterNumber,
                novel: novel,
                novelChapters: novelChaptersChunk.reversed()
            )
        } label: {
            Text("\(firstChapterNumber) - \(lastChapterNumber)")
                .foregroundColor(allChaptersRead ? .gray : .primary)
                .contextMenu {
                    Section {
                        Button {
                            if library.getNovelChaptersMarkedAsRead(novel: novel) >= novel.chapters.count {
                                return
                            }

                            for novelChapter in novelChaptersChunk {
                                Logger.library.info("Marking novel's '\(novel.title)' chapter '\(novelChapter.title)' as read...")

                                library.markNovelChapterAsRead(novel: novel, novelChapter: novelChapter)
                            }

                            library.save()
                        } label: {
                            Label("Mark as read", systemImage: "checkmark")
                        }

                        Button(role: .destructive) {
                            if library.getNovelChaptersMarkedAsRead(novel: novel) <= 0 {
                                return
                            }

                            for novelChapter in novelChaptersChunk {
                                Logger.library.info("Unmarking novel's '\(novel.title)' chapter '\(novelChapter.title)' as read...")

                                library.unmarkNovelChapterAsRead(novel: novel, novelChapter: novelChapter)
                            }

                            library.save()
                        } label: {
                            Label("Mark as not read", systemImage: "xmark")
                        }
                    }
                }
        }
    }
}

private struct NovelChaptersChunkDetails: View {
    let firstChapterNumber: String
    let lastChapterNumber: String
    let novel: Novel
    let novelChapters: [NovelChapter]

    var body: some View {
        Form {
            List(novelChapters, id: \.self) { novelChapter in
                NovelChapters(novel: novel, novelChapter: novelChapter)
            }
        }
        .navigationTitle("Chapters \(firstChapterNumber) - \(lastChapterNumber)")
    }
}

private struct NovelChapters: View {
    @Environment(\.library)
    var library

    let novel: Novel
    let novelChapter: NovelChapter

    var body: some View {
        NavigationLink {
            NovelChapterView(novel: novel, novelChapter: novelChapter)
        } label: {
            Text(novelChapter.title)
                .foregroundColor(library.isNovelChapterMarkedAsRead(novel: novel, novelChapter: novelChapter) ? .gray : .primary)
                .contextMenu {
                    Section {
                        Button {
                            Logger.library.info("Marking novel's '\(novel.title)' chapter '\(novelChapter.title)' as read...")

                            library.markNovelChapterAsRead(novel: novel, novelChapter: novelChapter)
                            library.save()
                        } label: {
                            Label("Mark as read", systemImage: "checkmark")
                        }

                        Button(role: .destructive) {
                            Logger.library.info("Unmarking novel's '\(novel.title)' chapter '\(novelChapter.title)' as read...")

                            library.unmarkNovelChapterAsRead(novel: novel, novelChapter: novelChapter)
                            library.save()
                        } label: {
                            Label("Mark as not read", systemImage: "xmark")
                        }
                    }
                }
        }
    }
}
