import SwiftUI

struct SettingsView: View {
    @Environment(\.settings)
    private var settings

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("General")) {
                    Picker("Appearance", selection: settings.appearanceIdBinding) {
                        Text("Auto").tag(0)
                        Text("Light").tag(1)
                        Text("Dark").tag(2)
                    }
                }
                
                Section(header: Text("Novels")) {
                    NavigationLink {
                        List(NovelProvider.allCases) { novelProvider in
                            Toggle(isOn: Binding<Bool>(
                                get: { settings.novelProviders.contains(novelProvider) },
                                set: { newValue in
                                    if newValue {
                                        settings.novelProviders.insert(novelProvider)
                                    } else {
                                        settings.novelProviders.remove(novelProvider)
                                    }
                                }
                            ), label: {
                                Text(novelProvider.implementation.details.name)
                            })
                        }
                        .navigationTitle("Providers")
                        .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        Text("Providers")
                    }
                    
                    Picker("Chapter Chunk Size", selection: settings.novelChapterChunkSizeBinding) {
                        ForEach(Array(stride(from: 50, through: 100, by: 5)), id: \.self) { chunkSize in
                            Text("\(chunkSize)").tag(chunkSize)
                        }
                    }

                    Picker("Chapter Horizontal Padding", selection: settings.novelChapterHorizontalPaddingBinding) {
                        ForEach(Array(stride(from: 2, through: 24, by: 2)), id: \.self) { padding in
                            Text("\(padding)").tag(CGFloat(padding))
                        }
                    }
                    
                    Picker("Chapter Vertical Padding", selection: settings.novelChapterVerticalPaddingBinding) {
                        ForEach(Array(stride(from: 2, through: 24, by: 2)), id: \.self) { padding in
                            Text("\(padding)").tag(CGFloat(padding))
                        }
                    }

                    Toggle(isOn: settings.markNovelChapterAsReadWhenFinishedBinding, label: {
                        Text("Mark Chapter as Read when Finished")
                    })

                    Toggle(isOn: settings.markNovelChapterAsReadWhenSwitchingBinding, label: {
                        Text("Mark Chapter as Read when Switching")
                    })
                }

                Section(header: Text("About")) {
                    LabeledContent {
                        Text("\(getAppVersion()).\(getAppBuild())")
                    } label: {
                        Text("Version")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func getAppVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "Unknown"
    }

    private func getAppBuild() -> String {
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return build
        }
        return "Unknown"
    }
}
