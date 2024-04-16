import Foundation

class LibraryStore: ObservableObject {
    @Published
    var library = Library(novels: [], novelChaptersRead: [:])

    init() {
        loadLibrary()
    }

    func loadLibrary() {
        Task.init {
            guard let data = try? Data(contentsOf: Self.fileURL()) else {
                return
            }

            let decoder = JSONDecoder()
            guard let decodedData = try? decoder.decode(Library.self, from: data) else {
                // In case of corrupted/outdated file, fall back to clean library.
                // TODO: Log this nicely and implement migration system for outdated libraries.
                return
            }

            DispatchQueue.main.async {
                self.library = decodedData
            }

        }
    }

    func saveLibrary() {
        Task.init {
            let encoder = JSONEncoder()
            guard let encodedData = try? encoder.encode(library) else {
                // I don't really know why this would fail.
                // TODO: Log this nicely.
                return
            }
            do {
                try encodedData.write(to: Self.fileURL())
            } catch {
                // TODO: Log this nicely.
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
