import Alamofire
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
                    site: "https://freewebnovel.com"
                )
            )
        }

        override func fetchNovels(searchTerm: String) async throws -> [NovelPreview] {
            let response = await AF.request(
                "\(details.site)/search/?searchkey=\(searchTerm)",
                method: .post,
                headers: [
                    "Content-Type": "application/x-www-form-urlencoded",
                    "Referer": details.site,
                    "Origin": details.site,
                ]
            )
            .serializingString()
            .response

            if let error = response.error {
                throw error
            }

            let document = try SwiftSoup.parse(response.value!)

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
        }

        override func parseNovel(path: String) async throws -> Novel {
            let response = await AF.request("\(details.site)\(path)")
                .serializingString()
                .response

            if let error = response.error {
                throw error
            }

            let document = try SwiftSoup.parse(response.value!)

            let title = try document.select("h1.tit").text()
            let coverURL = try document.select(".pic > img").attr("src")
            let summary = try document.select(".inner > p").eachText()
            let genres = try document.select("[title=Genre]")
                .first()!
                .nextElementSibling()!
                .text()
                .replacingOccurrences(of: "[\\t\\n]", with: "", options: .regularExpression)
                .components(separatedBy: ", ")
            let authors = try document.select("[title=Author]")
                .first()!
                .nextElementSibling()!
                .text()
                .replacingOccurrences(of: "[\\t\\n]", with: "", options: .regularExpression)
                .components(separatedBy: ", ")
            let status = try document.select("[title=Status]")
                .first()!
                .nextElementSibling()!
                .text()
                .replacingOccurrences(of: "[\\t\\n]", with: "", options: .regularExpression)
            let chapters: [NovelChapter] = try document.select("#idData > li > a")
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
        }

        override func parseNovelChapter(path: String) async throws -> [String] {
            let response = await AF.request("\(details.site)\(path)")
                .serializingString()
                .response

            if let error = response.error {
                throw error
            }

            let document = try SwiftSoup.parse(response.value!)

            let txt = try SwiftSoup.parse(try document.select("div.txt").html())
            let content = try txt.select("p").eachText()

            return content
        }
    }
}
