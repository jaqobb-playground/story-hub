import Foundation
import SwiftSoup

extension NovelProvider.Implementation {
    static let ScribbleHub = ScribbleHubNovelProvider()

    class ScribbleHubNovelProvider: NovelProvider.Implementation {
        fileprivate init() {
            super.init(
                provider: .scribbleHub,
                details: NovelProvider.Details(
                    name: "Scribble Hub",
                    site: "https://www.scribblehub.com",
                    version: "1.0",
                    batchSize: 15,
                    batchFetchPeriodNanos: 5_000_000_000
                )
            )
        }

        override func fetchNovels(searchTerm: String) async throws -> [NovelPreview] {
            do {
                let html = try await URLUtils.fetchHTML(
                    from: details.site + "/?s=" + searchTerm + "&post_type=fictionposts",
                    method: "POST"
                )
                let htmlAsDocument = try SwiftSoup.parse(html)

                return try htmlAsDocument.select(".search_main_box")
                    .array()
                    .map { element -> NovelPreview in
                        let path = try element.select(".search_title > a").attr("href")
                        let title = try element.select(".search_title > a").text()
                        let coverURL = try element.select(".search_img > img").attr("src")

                        return NovelPreview(
                            path: path.replacingOccurrences(of: details.site, with: ""),
                            title: title,
                            coverURL: coverURL,
                            provider: provider
                        )
                    }
                    .filter { !$0.title.isEmpty && !$0.path.isEmpty }
            } catch {
                throw NovelError.fetch(description: "Error fetching novels: \(error.localizedDescription)")
            }
        }

        override func parseNovel(path: String) async throws -> Novel {
            do {
                let html = try await URLUtils.fetchHTML(from: details.site + path + "?toc=-1#content1")
                let htmlAsDocument = try SwiftSoup.parse(html)

                let title = try htmlAsDocument.select(".fic_title").attr("title")
                let coverURL = try htmlAsDocument.select(".fic_image > img").attr("src")
                let summary = try htmlAsDocument.select(".wi_fic_desc > p").eachText()
                let genres = try htmlAsDocument.select(".fic_genre")
                    .enumerated()
                    .map { _, genreElement in
                        try genreElement.text()
                    }
                let authors = [try htmlAsDocument.select(".auth_name_fic").text()]
                var status = try htmlAsDocument.select(".rnd_stats").last()?.nextElementSibling()?.text()
                if let unwrappedStatus = status {
                    if unwrappedStatus.contains("Hiatus") {
                        status = "Hiatus"
                    } else if unwrappedStatus.contains("Ongoing") {
                        status = "Ongoing"
                    } else if unwrappedStatus.contains("Completed") {
                        status = "Completed"
                    } else {
                        status = "Unknown"
                    }
                } else {
                    status = "Unknown"
                }

                let chapterElements = try htmlAsDocument.select(".wi_fic_table > .toc_ol > .toc_w").enumerated().reversed()
                let chapters = try chapterElements.map { chapterIndex, chapterElement in
                    let chapterTitle = try chapterElement.select(".toc_a").text()
                    let chapterPath = try chapterElement.select(".toc_a").attr("href").replacingOccurrences(of: details.site, with: "")
                    let chapterNumber = chapterElements.count - chapterIndex

                    return NovelChapter(
                        path: chapterPath,
                        title: chapterTitle,
                        number: chapterNumber,
                        provider: provider
                    )
                }

                return Novel(
                    path: path,
                    title: title,
                    coverURL: coverURL,
                    summary: summary,
                    genres: genres,
                    authors: authors,
                    status: status!,
                    chapters: chapters,
                    chaptersRead: [],
                    dateAdded: Date.now,
                    dateUpdated: Date.now,
                    category: .reading,
                    provider: provider
                )
            } catch {
                print(error)
                throw NovelError.parse(description: "Error parsing novel '\(path)': \(error.localizedDescription)")
            }
        }

        override func parseNovelChapter(path: String) async throws -> [String] {
            do {
                let html = try await URLUtils.fetchHTML(from: details.site + path)
                let htmlAsDocument = try SwiftSoup.parse(html)

                let txt = try htmlAsDocument.select("div.chp_raw")
                let content = try txt.select("p").eachText()

                return content
            } catch {
                throw NovelError.parse(description: "Error parsing novel chapter '\(path)': \(error.localizedDescription)")
            }
        }
    }
}
