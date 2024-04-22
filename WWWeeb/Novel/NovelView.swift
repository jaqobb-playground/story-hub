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
                        novel = try await novelPreview.provider.implementation.parseNovel(path: novelPreview.path)
                    } catch {
                        AlertUtils.showAlert(title: "Failed to Fetch Novel '\(novelPreview.title)'", message: error.localizedDescription) { _ in
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
    @Environment(\.settings)
    private var settings
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
                    Label("Date Added", systemImage: "calendar.badge.plus")
                }

                LabeledContent {
                    Text(novel.dateUpdated.formatted())
                } label: {
                    Label("Date Updated", systemImage: "calendar.badge.clock")
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
            let novelChapterChunks = novel.chapters.splitIntoChunks(of: settings.novelChapterChunkSize)
            List(novelChapterChunks.reversed(), id: \.self) { novelChapters in
                NovelChaptersChunk(novel: novel, novelChapters: novelChapters)
            }
        }

        Section(header: Text("Quick Actions")) {
            NavigationLink {
                NovelChapterView(novel: novel, novelChapter: novel.chapters[0])
            } label: {
                Text("Start Reading")
            }

            let novelLastChapterReadNumber = novel.lastChapterReadNumber
            if novelLastChapterReadNumber == -1 || novel.chapters.count <= novelLastChapterReadNumber {
                Text("Continue Reading")
                    .foregroundColor(.gray)
            } else {
                NavigationLink {
                    NovelChapterView(novel: novel, novelChapter: novel.chapters[novelLastChapterReadNumber])
                } label: {
                    Text("Continue Reading")
                }
            }
        }

        Section {
            if !library.novels.contains(novel) {
                Button {
                    presentationMode.wrappedValue.dismiss()

                    library.novels.insert(novel)
                } label: {
                    Text("Add to Library")
                }
            } else {
                Button {
                    presentationMode.wrappedValue.dismiss()

                    library.novels.remove(novel)
                } label: {
                    Text("Remove from Library")
                }
                .foregroundColor(.red)
            }
        }
    }
}

private struct NovelChaptersChunk: View {
    @Environment(\.library)
    private var library

    let novel: Novel
    let novelChapters: [NovelChapter]
    @State
    var novelChaptersMidDownload: Bool = false

    private var firstChapterNumber: String {
        String(novelChapters.first!.number).trimmingCharacters(in: .whitespaces)
    }

    private var lastChapterNumber: String {
        String(novelChapters.last!.number).trimmingCharacters(in: .whitespaces)
    }

    private var allChaptersRead: Bool {
        return novelChapters.allSatisfy { novel.chaptersRead.contains($0.path) }
    }

    var body: some View {
        NavigationLink {
            NovelChaptersChunkDetails(
                firstChapterNumber: firstChapterNumber,
                lastChapterNumber: lastChapterNumber,
                novel: novel,
                novelChapters: novelChapters.reversed()
            )
        } label: {
            LabeledContent {
                if novelChaptersMidDownload {
                    ProgressView()
                }
            } label: {
                Text("\(firstChapterNumber) - \(lastChapterNumber)")
                    .foregroundColor(allChaptersRead ? .gray : .primary)
                    .contextMenu {
                        Section {
                            Button {
                                Task.init {
                                    novelChaptersMidDownload = true

                                    let novelChapterChunks = novelChapters.splitIntoChunks(of: novel.provider.implementation.details.batchSize)
                                    for (novelChapterChunkIndex, novelChapters) in novelChapterChunks.enumerated() {
                                        await withTaskGroup(of: Void.self) { group in
                                            for novelChapter in novelChapters {
                                                group.addTask {
                                                    await novelChapter.fetchContent()
                                                }
                                            }
                                        }

                                        if novelChapterChunkIndex < novelChapterChunks.count - 1 {
                                            try? await Task.sleep(nanoseconds: novel.provider.implementation.details.batchFetchPeriodNanos)
                                        }
                                    }

                                    novelChaptersMidDownload = false
                                }
                            } label: {
                                if novelChapters.contains(where: { $0.content != nil }) {
                                    Label("Redownload All", systemImage: "arrow.clockwise")
                                } else {
                                    Label("Download All", systemImage: "square.and.arrow.down")
                                }
                            }

                            Button(role: .destructive) {
                                for novelChapter in novelChapters {
                                    novelChapter.content = nil
                                }
                            } label: {
                                Label("Remove All Downloads", systemImage: "trash")
                            }
                        }

                        Section {
                            Button {
                                novel.chaptersRead.formUnion(novelChapters.map({ $0.path }))
                            } label: {
                                Label("Mark as Read", systemImage: "checkmark")
                            }

                            Button(role: .destructive) {
                                novel.chaptersRead.subtract(novelChapters.map({ $0.path }))
                            } label: {
                                Label("Unmark as Read", systemImage: "xmark")
                            }
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
                NovelChapterCell(novel: novel, novelChapter: novelChapter)
            }
        }
        .navigationTitle("Chapters \(firstChapterNumber) - \(lastChapterNumber)")
    }
}

private struct NovelChapterCell: View {
    @Environment(\.presentationMode)
    private var presentationMode
    @Environment(\.library)
    private var library

    let novel: Novel
    let novelChapter: NovelChapter
    @State
    var novelChapterMidDownload: Bool = false

    var body: some View {
        NavigationLink {
            NovelChapterView(novel: novel, novelChapter: novelChapter)
        } label: {
            LabeledContent {
                if novelChapterMidDownload {
                    ProgressView()
                }
            } label: {
                Text(novelChapter.title)
                    .foregroundColor(novel.chaptersRead.contains(novelChapter.path) ? .gray : .primary)
                    .contextMenu {
                        Section {
                            Button {
                                Task.init {
                                    novelChapterMidDownload = true

                                    await novelChapter.fetchContent()

                                    novelChapterMidDownload = false
                                }
                            } label: {
                                if novelChapter.content != nil {
                                    Label("Redownload", systemImage: "arrow.clockwise")
                                } else {
                                    Label("Download", systemImage: "square.and.arrow.down")
                                }
                            }

                            Button(role: .destructive) {
                                novelChapter.content = nil
                            } label: {
                                Label("Remove Download", systemImage: "trash")
                            }
                        }

                        Section {
                            Button {
                                novel.chaptersRead.insert(novelChapter.path)
                            } label: {
                                Label("Mark as Read", systemImage: "checkmark")
                            }

                            Button(role: .destructive) {
                                novel.chaptersRead.remove(novelChapter.path)
                            } label: {
                                Label("Unmark as Read", systemImage: "xmark")
                            }
                        }
                    }
            }
        }
    }
}
