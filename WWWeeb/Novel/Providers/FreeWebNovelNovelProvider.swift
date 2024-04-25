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
                    from: details.site + "/search/",
                    method: "POST",
                    headers: [
                        "Content-Type": "application/x-www-form-urlencoded'",
                        "Referer": details.site,
                        "Origin": details.site,
                    ],
                    query: [
                        "searchkey": searchTerm,
                    ]
                )
                let document = try SwiftSoup.parse(html)

                return try document.select(".li-row > .li > .con")
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
                let document = try SwiftSoup.parse(html)

                let title = try document.select("h1.tit").text()
                let coverURL = try document.select(".pic > img").attr("src")
                let summary = try document.select(".inner > p").eachText()
                let genres = (try document.select("[title=Genre]").first()?.nextElementSibling()?.text().replacingOccurrences(of: "[\t\n]", with: "", options: .regularExpression).components(separatedBy: ", ")) ?? []
                let authors = (try document.select("[title=Author]").first()?.nextElementSibling()?.text().replacingOccurrences(of: "[\t\n]", with: "", options: .regularExpression).components(separatedBy: ", ")) ?? []
                let status = (try document.select("[title=Status]").first()?.nextElementSibling()?.text().replacingOccurrences(of: "[\t\n]", with: "", options: .regularExpression)) ?? ""
                let chapters: [NovelChapter] = try document.select("#idData > li > a")
                    .enumerated()
                    .map { chapterIndex, chapterElement in
                        let chapterTitle = (try? chapterElement.attr("title")) ?? "Chapter \(chapterIndex + 1)"
                        let chapterPath = (try? chapterElement.attr("href")) ?? path + "/\(chapterIndex + 1)"

                        return NovelChapter(
                            path: chapterPath,
                            title: chapterTitle,
                            number: chapterIndex + 1,
                            content: nil,
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
                    lastChapterReadNumber: -1,
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
                let document = try SwiftSoup.parse(html)
                let documentTxt = try SwiftSoup.parse(try document.select("div.txt").html())

                return try documentTxt.select("p").eachText()
            } catch {
                throw NovelError.parse(description: "Error parsing novel chapter '\(path)': \(error.localizedDescription)")
            }
        }
    }
}
