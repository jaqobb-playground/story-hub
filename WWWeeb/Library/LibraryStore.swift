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

            do {
                let decoder = JSONDecoder()
                let decodedData = try decoder.decode(Library.self, from: data)

                DispatchQueue.main.async {
                    self.library = decodedData
                }
            } catch {
                DispatchQueue.main.async {
                    fatalError(error.localizedDescription)
                }
            }
        }
    }

    func saveLibrary() {
        Task.init {
            do {
                let encoder = JSONEncoder()
                let encodedData = try encoder.encode(library)
                try encodedData.write(to: Self.fileURL())
            } catch {
                DispatchQueue.main.async {
                    fatalError(error.localizedDescription)
                }
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
