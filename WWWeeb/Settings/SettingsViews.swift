import SwiftUI

struct BrowseSettingsSheet: View {
    @Environment(\.settings)
    private var settings

    @Binding
    var settingsSheetVisible: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Novel Providers")) {
                    List(NovelProvider.allCases) { novelProvider in
                        NavigationLink {
                            Form {
                                LabeledContent {
                                    Text(novelProvider.id)
                                } label: {
                                    Text("ID")
                                }
                                
                                LabeledContent {
                                    Text(novelProvider.implementation.details.name)
                                } label: {
                                    Text("Name")
                                }
                                
                                LabeledContent {
                                    Text(novelProvider.implementation.details.site)
                                } label: {
                                    Text("Site")
                                }
                                
                                LabeledContent {
                                    Text(novelProvider.implementation.details.version)
                                } label: {
                                    Text("Version")
                                }
                            }
                            .navigationTitle(novelProvider.implementation.details.name)
                            .navigationBarTitleDisplayMode(.inline)
                        } label: {
                            Toggle(isOn: Binding<Bool>(
                                get: { settings.novelProviders.contains(novelProvider) },
                                set: { newValue in
                                    if newValue {
                                        settings.novelProviders.insert(novelProvider)
                                    } else {
                                        settings.novelProviders.remove(novelProvider)
                                    }
                                }
                            )) {
                                Text(novelProvider.implementation.details.name)
                            }
                        }
                    }
                }

                Section(header: Text("Comic Providers")) {
                    Text("We are not quite there yet! :(")
                }
                
                AboutSection()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        settingsSheetVisible = false
                    }
                }
            }
        }
    }
}

struct LibrarySettingsSheet: View {
    @Environment(\.settings)
    private var settings

    @Binding
    var settingsSheetVisible: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Novels")) {
                    NavigationLink {
                        List {
                            ForEach(Novel.Filter.allCases) { novelFilter in
                                Toggle(isOn: Binding<Bool>(
                                    get: { settings.novelFilters.contains(novelFilter) },
                                    set: { newValue in
                                        if newValue {
                                            settings.novelFilters.insert(novelFilter)
                                        } else {
                                            settings.novelFilters.remove(novelFilter)
                                        }
                                    }
                                )) {
                                    Text(novelFilter.name)
                                }
                            }
                        }
                        .navigationTitle("Filters")
                        .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        Text("Filters")
                    }

                    Picker("Sort By", selection: Binding<Novel.SortingMode>(
                        get: { settings.novelSortingMode },
                        set: { settings.novelSortingMode = $0 }
                    )) {
                        ForEach(Novel.SortingMode.allCases) { novelSortingMode in
                            Text("\(novelSortingMode.name)").tag(novelSortingMode)
                        }
                    }
                }

                Section(header: Text("Comics")) {
                    Text("We are not quite there yet! :(")
                }
                
                AboutSection()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        settingsSheetVisible = false
                    }
                }
            }
        }
    }
}

struct NovelSettingsSheet: View {
    @Environment(\.settings)
    private var settings

    @Binding
    var settingsSheetVisible: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("View")) {
                    Picker("Chunk Size", selection: Binding<Int>(
                        get: { settings.novelChapterChunkSize },
                        set: { settings.novelChapterChunkSize = $0 }
                    )) {
                        ForEach(Array(stride(from: 50, through: 100, by: 5)), id: \.self) { chunkSize in
                            Text("\(chunkSize)").tag(chunkSize)
                        }
                    }
                }

                Section(header: Text("Chapters")) {
                    Picker("Font Size", selection: Binding<CGFloat>(
                        get: { settings.novelChapterFontSize },
                        set: { settings.novelChapterFontSize = $0 }
                    )) {
                        ForEach(Array(stride(from: 6, through: 30, by: 2)), id: \.self) { size in
                            Text("\(size)").tag(CGFloat(size))
                        }
                    }

                    Picker("Horizontal Padding", selection: Binding<CGFloat>(
                        get: { settings.novelChapterHorizontalPadding },
                        set: { settings.novelChapterHorizontalPadding = $0 }
                    )) {
                        ForEach(Array(stride(from: 2, through: 24, by: 2)), id: \.self) { padding in
                            Text("\(padding)").tag(CGFloat(padding))
                        }
                    }

                    Picker("Vertical Padding", selection: Binding<CGFloat>(
                        get: { settings.novelChapterVerticalPadding },
                        set: { settings.novelChapterVerticalPadding = $0 }
                    )) {
                        ForEach(Array(stride(from: 2, through: 24, by: 2)), id: \.self) { padding in
                            Text("\(padding)").tag(CGFloat(padding))
                        }
                    }

                    Toggle(isOn: Binding<Bool>(
                        get: { settings.markNovelChapterAsReadWhenFinished },
                        set: { settings.markNovelChapterAsReadWhenFinished = $0 }
                    ), label: {
                        Text("Mark as Read when Finished")
                    })

                    Toggle(isOn: Binding(
                        get: { settings.markNovelChapterAsReadWhenSwitching },
                        set: { settings.markNovelChapterAsReadWhenSwitching = $0 }
                    ), label: {
                        Text("Mark as Read when Switching")
                    })
                }
                
                AboutSection()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        settingsSheetVisible = false
                    }
                }
            }
        }
    }
}

private struct AboutSection: View {
    var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "Unknown"
    }
    var appBuild: String {
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return build
        }
        return "Unknown"
    }
    
    
    var body: some View {
        Section(header: Text("About")) {
            LabeledContent {
                Text("\(appVersion).\(appBuild)")
            } label: {
                Text("Version")
            }
        }
    }
}
