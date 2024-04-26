import Foundation
import SwiftSoup

extension NovelProvider.Implementation {
    static let FreeWebNovel = FreeWebNovelNovelProvider()

    class FreeWebNovelNovelProvider: NovelProvider.Implementation {
        fileprivate init() {
            super.init(
                provider: .freeWebNovel,
                details: NovelProvider.Details(
                    name: "Free Web Novel",
                    site: "https://freewebnovel.com",
                    version: "1.0",
                    batchSize: 15,
                    batchFetchPeriodNanos: 5_000_000_000
                )
            )
        }

        override func fetchNovels(searchTerm: String) async throws -> [NovelPreview] {
            do {
                let html = try await URLUtils.fetchHTML(
                    from: details.site + "/search/?searchkey=" + searchTerm,
                    method: "POST",
                    headers: [
                        "Content-Type": "application/x-www-form-urlencoded",
                        "Referer": details.site,
                        "Origin": details.site,
                    ]
                )
                let htmlAsDocument = try SwiftSoup.parse(html)

                return try htmlAsDocument.select(".li-row > .li > .con")
                    .array()
                    .map { element -> NovelPreview in
                        let path = try element.select("h3 > a").attr("href")
                        let title = try element.select(".tit").text()
                        let coverURL = try element.select(".pic > a > img").attr("src")

                        return NovelPreview(
                            path: path,
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
                let html = try await URLUtils.fetchHTML(from: details.site + path)
                let htmlAsDocument = try SwiftSoup.parse(html)

                let title = try htmlAsDocument.select("h1.tit").text()
                let coverURL = try htmlAsDocument.select(".pic > img").attr("src")
                let summary = try htmlAsDocument.select(".inner > p").eachText()
                let genres = (try htmlAsDocument.select("[title=Genre]").first()?.nextElementSibling()?.text().replacingOccurrences(of: "[\t\n]", with: "", options: .regularExpression).components(separatedBy: ", ")) ?? ["Unknown"]
                let authors = (try htmlAsDocument.select("[title=Author]").first()?.nextElementSibling()?.text().replacingOccurrences(of: "[\t\n]", with: "", options: .regularExpression).components(separatedBy: ", ")) ?? ["Unknown"]
                let status = (try htmlAsDocument.select("[title=Status]").first()?.nextElementSibling()?.text().replacingOccurrences(of: "[\t\n]", with: "", options: .regularExpression)) ?? "Unknown"
                let chapters: [NovelChapter] = try htmlAsDocument.select("#idData > li > a")
                    .enumerated()
                    .map { chapterIndex, chapterElement in
                        let chapterTitle = try chapterElement.attr("title")
                        let chapterPath = try chapterElement.attr("href")

                        return NovelChapter(
                            path: chapterPath,
                            title: chapterTitle,
                            number: chapterIndex + 1,
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
                    status: status,
                    chapters: chapters,
                    chaptersRead: [],
                    dateAdded: Date.now,
                    dateUpdated: Date.now,
                    category: .reading,
                    provider: provider
                )
            } catch {
                throw NovelError.parse(description: "Error parsing novel '\(path)': \(error.localizedDescription)")
            }
        }

        override func parseNovelChapter(path: String) async throws -> [String] {
            do {
                let html = try await URLUtils.fetchHTML(from: details.site + path)
                let htmlAsDocument = try SwiftSoup.parse(html)

                let txt = try SwiftSoup.parse(try htmlAsDocument.select("div.txt").html())
                let content = try txt.select("p").eachText()

                return content
            } catch {
                throw NovelError.parse(description: "Error parsing novel chapter '\(path)': \(error.localizedDescription)")
            }
        }
    }
}
