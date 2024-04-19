import Foundation
import SwiftSoup

extension Source {
    static let LibRead = LibReadSource()

    class LibReadSource: Source {
        fileprivate init() {
            super.init(id: "lib_read", name: "Lib Read", site: "https://libread.org", version: "1.0", type: .lib_read)
        }

        override func parseNovel(novelPath: String) async throws -> Novel {
            do {
                let html = try await URLUtils.fetchHTML(from: site + novelPath)
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
                        let title = (try? chapterElement.attr("title")) ?? "Chapter \(chapterIndex + 1)"
                        let path = (try? chapterElement.attr("href")) ?? novelPath + "/\(chapterIndex + 1)"

                        return NovelChapter(
                            path: path,
                            title: title,
                            number: chapterIndex + 1,
                            releaseTime: nil
                        )
                    }

                return Novel(
                    path: novelPath,
                    title: title,
                    coverURL: coverURL,
                    summary: summary,
                    genres: genres,
                    authors: authors,
                    status: status,
                    chapters: chapters,
                    chaptersRead: Set(),
                    dateAdded: Date.now,
                    dateUpdated: Date.now,
                    category: .reading,
                    sourceType: type
                )
            } catch {
                throw NovelError.parse(description: "Error parsing novel '\(novelPath)': \(error.localizedDescription)")
            }
        }

        override func parseNovelChapter(novelChapterPath: String) async throws -> NovelChapterContent {
            do {
                let html = try await URLUtils.fetchHTML(from: site + novelChapterPath)
                let document = try SwiftSoup.parse(html)
                let documentTxt = try SwiftSoup.parse(try document.select("div.txt").html())

                let title = try documentTxt.select("h4").text()
                let contents = try documentTxt.select("p").eachText()

                return NovelChapterContent(
                    title: title,
                    contents: contents
                )
            } catch {
                throw NovelError.parse(description: "Error parsing novel chapter '\(novelChapterPath)': \(error.localizedDescription)")
            }
        }

        override func fetchNovels(searchTerm: String) async throws -> [NovelPreview] {
            do {
                let html = try await URLUtils.fetchHTML(
                    from: site + "/search/",
                    method: "POST",
                    headers: [
                        "Content-Type": "application/x-www-form-urlencoded'",
                        "Referer": site,
                        "Origin": site,
                    ],
                    query: [
                        "searchkey": searchTerm,
                    ]
                )
                let document = try SwiftSoup.parse(html)

                let novels = try document.select(".li-row > .li > .con").array().map { element -> NovelPreview in
                    let path = try element.select("h3 > a").attr("href")
                    let title = try element.select(".tit").text()
                    let coverURL = try element.select(".pic > a > img").attr("src")

                    return NovelPreview(
                        path: path,
                        title: title,
                        coverURL: coverURL,
                        sourceType: self.type
                    )
                }

                return novels.filter { !$0.title.isEmpty && !$0.path.isEmpty }
            } catch {
                throw NovelError.fetch(description: "Error fetching novels: \(error.localizedDescription)")
            }
        }
    }
}
