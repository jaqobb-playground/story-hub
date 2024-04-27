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
    var settingsSheetVisible = false

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
        if let novel = novel {
            Form {
                NovelInformation(novel)
            }
            .modifier(NovelViewModifier(settingsSheetVisible: $settingsSheetVisible, title: novel.title))
            .refreshable {
                await Task {
                    await novel.update()
                }
                .value
            }
        } else {
            ZStack {
                Spacer()
                    .containerRelativeFrame([.horizontal, .vertical])

                ProgressView()
                    .scaleEffect(2)
            }
            .modifier(NovelViewModifier(settingsSheetVisible: $settingsSheetVisible, title: novelPreview!.title))
            .onAppear {
                fetchNovel()
            }
        }
    }

    private func fetchNovel() {
        Task {
            do {
                novel = try await novelPreview!.provider.implementation.parseNovel(path: novelPreview!.path)
            } catch {
                AlertUtils.showAlert(title: "Failed to Fetch Novel '\(novelPreview!.title)'", message: error.localizedDescription) { _ in
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct NovelViewModifier: ViewModifier {
    @Binding
    var settingsSheetVisible: Bool

    var title: String

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(id: "Setting", placement: .topBarTrailing) {
                    Button {
                        settingsSheetVisible = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $settingsSheetVisible) {
                NovelSettingsSheet(settingsSheetVisible: $settingsSheetVisible)
            }
    }
}

struct NovelInformation: View {
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

                VStack(alignment: .center, spacing: 8) {
                    KFImage(URL(string: novel.coverURL))
                        .placeholder { progress in
                            ProgressView(progress)
                        }
                        .cornerRadius(10)

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
            LabeledContent {
                Text(novel.provider.implementation.details.name)
            } label: {
                Label("Provider", systemImage: "books.vertical")
            }

            NavigationLink {
                List(novel.authors, id: \.self) { author in
                    Text(author)
                }
                .navigationTitle("Authors")
                .navigationBarTitleDisplayMode(.inline)
            } label: {
                Label("Authors", systemImage: "person")
            }

            NavigationLink {
                List(novel.genres, id: \.self) { genre in
                    Text(genre)
                }
                .navigationTitle("Genres")
                .navigationBarTitleDisplayMode(.inline)
            } label: {
                Label("Genres", systemImage: "list.bullet")
            }

            NavigationLink {
                List(novel.summary, id: \.self) { summaryContent in
                    Text(summaryContent)
                }
                .navigationTitle("Summary")
                .navigationBarTitleDisplayMode(.inline)
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

                Picker(selection: Binding<Novel.Category>(
                    get: { novel.category },
                    set: { novel.category = $0 }
                )) {
                    ForEach(Novel.Category.allCases, id: \.self) { category in
                        Text(category.name).tag(category)
                    }
                } label: {
                    Label("Category", systemImage: "book")
                }
            }
        }

        if !novel.chapters.isEmpty {
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

            Section(header: Text("Chapters")) {
                let novelChapterChunks = novel.chapters.chunked(into: settings.novelChapterChunkSize)
                List(novelChapterChunks.reversed(), id: \.self) { novelChapters in
                    NovelChaptersChunk(novel: novel, novelChapters: novelChapters)
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

struct NovelChaptersChunk: View {
    @Environment(\.library)
    private var library

    let novel: Novel
    let novelChapters: [NovelChapter]

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
            Text("\(firstChapterNumber) - \(lastChapterNumber)")
                .foregroundColor(allChaptersRead ? .gray : .primary)
                .contextMenu {
                    Section {
                        Button {
                            novel.chaptersRead.formUnion(novelChapters.map({ $0.path }))
                        } label: {
                            Label("Mark as Read", systemImage: "checkmark")
                        }

                        Button(role: .destructive) {
                            novel.chaptersRead.subtract(novelChapters.map({ $0.path }))
                        } label: {
                            Label("Mark as Unread", systemImage: "xmark")
                        }
                    }
                }
        }
    }
}

struct NovelChaptersChunkDetails: View {
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
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NovelChapterCell: View {
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
                            novel.chaptersRead.insert(novelChapter.path)
                        } label: {
                            Label("Mark as Read", systemImage: "checkmark")
                        }

                        Button(role: .destructive) {
                            novel.chaptersRead.remove(novelChapter.path)
                        } label: {
                            Label("Mark as Unread", systemImage: "xmark")
                        }
                    }
                }
        }
    }
}

struct NovelPreviewCell: View {
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
                    .placeholder { progress in
                        ProgressView(progress)
                    }
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
            .contextMenu {
                if let novel = novel {
                    Button(role: .destructive) {
                        library.novels.remove(novel)
                    } label: {
                        Label("Remove from Library", systemImage: "bookmark.slash")
                    }
                } else {
                    Button {
                        Task {
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
        .buttonStyle(PlainButtonStyle())
    }
}

struct NovelCell: View {
    @Environment(\.library)
    private var library

    let novel: Novel

    var novelChaptersReadString: String {
        String(novel.chaptersRead.count).trimmingCharacters(in: .whitespaces)
    }

    var novelChaptersTotalString: String {
        String(novel.chapters.count).trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        NavigationLink {
            NovelView(novel: novel)
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    KFImage(URL(string: novel.coverURL))
                        .placeholder { progress in
                            ProgressView(progress)
                        }
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(10)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .blur(radius: novel.updating ? 5 : 0, opaque: false)
                        .animation(.easeInOut(duration: 0.5), value: novel.updating)

                    if novel.chaptersRead.count < novel.chapters.count {
                        ZStack(alignment: .topTrailing) {
                            Color.clear

                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                                .background(Color.white)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.black, lineWidth: 1))
                                .shadow(radius: 3)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 6)
                        }
                    }

                    if novel.updating {
                        ProgressView()
                            .scaleEffect(2)
                            .animation(.easeInOut(duration: 0.5), value: novel.updating)
                    }
                }

                Text(novel.title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text("\(novelChaptersReadString)/\(novelChaptersTotalString)".trimmingCharacters(in: .whitespaces))
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .contextMenu {
                if !novel.chapters.isEmpty {
                    Section {
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
                }

                Section {
                    Button {
                        novel.chaptersRead.formUnion(novel.chapters.map({ $0.path }))
                    } label: {
                        Label("Mark as Read", systemImage: "checkmark")
                    }

                    Button(role: .destructive) {
                        novel.chaptersRead.subtract(novel.chapters.map({ $0.path }))
                    } label: {
                        Label("Mark as Unread", systemImage: "xmark")
                    }
                }

                Section {
                    Menu {
                        Picker(selection: Binding<Novel.Category>(
                            get: { novel.category },
                            set: { novel.category = $0 }
                        )) {
                            ForEach(Novel.Category.allCases) { novelCategory in
                                Text("\(novelCategory.name)").tag(novelCategory)
                            }
                        } label: {}
                    } label: {
                        Label("Change Category To", systemImage: "book")
                    }

                    Button {
                        Task {
                            await novel.update()
                        }
                    } label: {
                        Label("Update", systemImage: "arrow.clockwise")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        library.novels.remove(novel)
                    } label: {
                        Label("Remove from Library", systemImage: "bookmark.slash")
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NovelChapterView: View {
    @Environment(\.presentationMode)
    private var presentationMode
    @Environment(\.settings)
    private var settings

    @State
    var settingsSheetVisible = false

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
        _novelChapterContent = State(initialValue: nil)
    }

    var body: some View {
        ScrollViewReader { reader in
            ScrollView(.vertical) {
                if let novelChapterContent = novelChapterContent {
                    VStack {
                        ForEach(novelChapterContent.indices, id: \.self) { index in
                            Text(novelChapterContent[index])
                                .font(.system(size: settings.novelChapterFontSize))
                                .padding(.horizontal, settings.novelChapterHorizontalPadding)
                                .padding(.vertical, settings.novelChapterVerticalPadding)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(index)
                        }
                    }

                    LazyVStack {
                        Color.clear
                            .onAppear {
                                // With LazyVStack, when this appears it means we've reached the bottom (== chapter read).
                                if settings.markNovelChapterAsReadWhenFinished {
                                    novel.chaptersRead.insert(novelChapter.path)
                                }
                            }
                    }
                } else {
                    ZStack {
                        Spacer()
                            .containerRelativeFrame([.horizontal, .vertical])

                        ProgressView()
                            .scaleEffect(2)
                    }
                }
            }
            .navigationTitle(novelChapter.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(id: "Setting", placement: .topBarTrailing) {
                    Button {
                        settingsSheetVisible = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }

                ToolbarItem(id: "Previous Chapter", placement: .bottomBar) {
                    if novelChapter.number > novelFirstChapterNumber {
                        Button {
                            reader.scrollTo(0, anchor: .top)

                            if settings.markNovelChapterAsReadWhenSwitching {
                                novel.chaptersRead.insert(novelChapter.path)
                            }
                            novelChapterContent = nil
                            novelChapter = novel.chapters[novelChapterIndex - 1]

                            fetchNovelChapterContent()
                        } label: {
                            Label("Previous Chapter", systemImage: "arrow.backward")
                        }
                    } else {
                        Spacer()
                    }
                }

                // Any better way to do this?
                ToolbarItem(id: "Sneaky Spacer", placement: .status) {
                    Spacer()
                }

                ToolbarItem(id: "Next Chapter", placement: .bottomBar) {
                    if novelChapter.number < novelLastChapterNumber {
                        Button {
                            reader.scrollTo(0, anchor: .top)

                            if settings.markNovelChapterAsReadWhenSwitching {
                                novel.chaptersRead.insert(novelChapter.path)
                            }
                            novelChapterContent = nil
                            novelChapter = novel.chapters[novelChapterIndex + 1]

                            fetchNovelChapterContent()
                        } label: {
                            Label("Next Chapter", systemImage: "arrow.forward")
                        }
                    } else {
                        Spacer()
                    }
                }
            }
            .sheet(isPresented: $settingsSheetVisible) {
                NovelSettingsSheet(settingsSheetVisible: $settingsSheetVisible)
            }
            .onAppear {
                fetchNovelChapterContent()
            }
        }
    }

    private func fetchNovelChapterContent() {
        Task {
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
