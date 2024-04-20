import Kingfisher
import OSLog
import SwiftData
import SwiftUI

struct NovelView: View {
    @Environment(\.presentationMode)
    private var presentationMode
    @Environment(\.library)
    private var library

    @State
    var novel: Novel?
    var novelPreview: NovelPreview?

    init(novel: Novel) {
        _novel = State(initialValue: novel)
    }

    init(novelPreview: NovelPreview) {
        self.novelPreview = novelPreview
    }

    var body: some View {
        Form {
            if let novel = novel {
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
        .navigationTitle(novel != nil ? novel!.title : novelPreview!.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let novelPreview = novelPreview {
                Task.init {
                    do {
                        novel = try await novelPreview.sourceType.source.parseNovel(novelPath: novelPreview.path)
                    } catch {
                        AlertUtils.showAlert(title: "Failed to fetch novel '\(novelPreview.title)'", message: error.localizedDescription) { _ in
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
        }
        .refreshable {
            if let novel = novel {
                await novel.update()
            }
        }
    }
}

private struct NovelInformation: View {
    @Environment(\.presentationMode)
    private var presentationMode
    @Environment(\.library)
    private var library

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
                Label("Summary", systemImage: "text.book.closed")
            }

            LabeledContent {
                Text(novel.status.capitalized)
            } label: {
                Label("Status", systemImage: "clock")
            }

            if library.novels.contains(novel) {
                LabeledContent {
                    Text(novel.dateAdded.formatted())
                } label: {
                    Label("Date added", systemImage: "calendar.badge.plus")
                }

                LabeledContent {
                    Text(novel.dateUpdated.formatted())
                } label: {
                    Label("Date updated", systemImage: "calendar.badge.clock")
                }

                Picker(selection: novel.categoryBinding) {
                    ForEach(Novel.Category.allCases, id: \.self) { category in
                        Text(category.name).tag(category)
                    }
                } label: {
                    Label("Category", systemImage: "book")
                }
            }
        }

        Section(header: Text("Chapters")) {
            let novelChapterChunked = novel.splitChaptersIntoChunks(chunkSize: 100)

            List(novelChapterChunked.reversed(), id: \.self) { novelChaptersChunk in
                NovelChaptersChunk(novel: novel, novelChaptersChunk: novelChaptersChunk)
            }
        }

        Section {
            if !library.novels.contains(novel) {
                Button("Add to library") {
                    presentationMode.wrappedValue.dismiss()

                    library.novels.insert(novel)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Button("Remove from library") {
                    presentationMode.wrappedValue.dismiss()

                    library.novels.remove(novel)
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

private struct NovelChaptersChunk: View {
    @Environment(\.library)
    private var library

    let novel: Novel
    let novelChaptersChunk: [NovelChapter]

    private var firstChapterNumber: String {
        String(novelChaptersChunk.first!.number).trimmingCharacters(in: .whitespaces)
    }

    private var lastChapterNumber: String {
        String(novelChaptersChunk.last!.number).trimmingCharacters(in: .whitespaces)
    }

    private var allChaptersRead: Bool {
        return novelChaptersChunk.allSatisfy { novel.chaptersRead.contains($0.path) }
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
                            novel.chaptersRead.formUnion(novelChaptersChunk.map({ $0.path }))
                        } label: {
                            Label("Mark as read", systemImage: "checkmark")
                        }

                        Button(role: .destructive) {
                            novel.chaptersRead.subtract(novelChaptersChunk.map({ $0.path }))
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
    @Environment(\.presentationMode)
    private var presentationMode
    @Environment(\.library)
    private var library

    let novel: Novel
    let novelChapter: NovelChapter

    var body: some View {
        NavigationLink {
            NovelChapterView(novel: novel, novelChapter: novelChapter)
        } label: {
            Text(novelChapter.title)
                .foregroundColor(novel.chaptersRead.contains(novelChapter.path) ? .gray : .primary)
                .contextMenu {
                    Section {
                        Button {
                            Task.init {
                                await novelChapter.fetchContent()
                            }
                        } label: {
                            Label("Download", systemImage: "square.and.arrow.down")
                        }

                        Button {
                            novel.chaptersRead.insert(novelChapter.path)
                        } label: {
                            Label("Mark as read", systemImage: "checkmark")
                        }

                        Button(role: .destructive) {
                            novel.chaptersRead.remove(novelChapter.path)
                        } label: {
                            Label("Mark as not read", systemImage: "xmark")
                        }
                    }
                }
        }
    }
}
