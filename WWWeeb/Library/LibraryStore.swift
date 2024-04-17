import Foundation
import OSLog

class LibraryStore: ObservableObject {
    @Published
    var library = Library(novels: [], novelChaptersRead: [:])

    init() {
        loadLibrary()
    }

    func loadLibrary() {
        Task.init {
            do {
                Logger.library.info("Loading library...")

                guard let data = try? Data(contentsOf: Self.fileURL()) else {
                    return
                }

                let decoder = JSONDecoder()
                let decodedData = try decoder.decode(Library.self, from: data)

                DispatchQueue.main.async {
                    self.library = decodedData
                }
            } catch {
                // TODO: Implement migration system for outdated libraries.
                Logger.library.warning("Failed to load library: \(error.localizedDescription)")
            }
        }
    }

    func saveLibrary() {
        Task.init {
            do {
                Logger.library.info("Saving library...")

                let encoder = JSONEncoder()
                let encodedData = try encoder.encode(library)
                try encodedData.write(to: Self.fileURL())
            } catch {
                Logger.library.warning("Failed to save library: \(error.localizedDescription)")
            }
        }
    }

    static func fileURL() throws -> URL {
        return try FileManager.default
            .url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            .appendingPathComponent("library.data")
    }
}
