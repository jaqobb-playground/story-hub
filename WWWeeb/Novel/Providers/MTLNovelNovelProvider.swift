import Foundation
import SwiftSoup

extension NovelProvider.Implementation {
    static let MTLNovel = MTLNovelNovelProvider()

    class MTLNovelNovelProvider: NovelProvider.Implementation {
        fileprivate init() {
            super.init(
                provider: .mtlNovel,
                details: NovelProvider.Details(name: "MTL Novel", site: "https://www.mtlnovel.com")
            )
        }

        override func fetchNovels(searchTerm: String) async throws -> [NovelPreview] {
            do {
                let json = try await URLUtils.fetchContent(
                    from: details.site + "/wp-admin/admin-ajax.php?action=autosuggest&q=" + searchTerm + "&__amp_source_origin=https%3A%2F%2Fwww.mtlnovel.com",
                    method: "POST",
                    headers: [
                        "Alt-Used": "www.mtlnovel.com",
                    ]
                )
                let jsonAsDictionary = try JSONSerialization.jsonObject(with: json.data(using: .utf8)!, options: []) as! [String: Any]

                var novelPreviews: [NovelPreview] = []

                let items = jsonAsDictionary["items"] as! [Any]
                let itemResults = (items[0] as! [String: Any])["results"] as! [[String: Any]]
                for itemResult in itemResults {
                    let path = (itemResult["permalink"] as! String).replacingOccurrences(of: details.site, with: "")
                    let title = (itemResult["title"] as! String)
                        .replacingOccurrences(of: "<\\/?strong>", with: "", options: .regularExpression)
                        .replacingOccurrences(of: "&#8217;", with: "’")
                    let coverURL = (itemResult["thumbnail"] as! String)

                    novelPreviews.append(NovelPreview(
                        path: path,
                        title: title,
                        coverURL: coverURL,
                        provider: .mtlNovel
                    ))
                }

                return novelPreviews
            } catch {
                throw NovelError.fetch(description: "Error fetching novels: \(error.localizedDescription)")
            }
        }

        override func parseNovel(path: String) async throws -> Novel {
            do {
                let headers = [
                    "Referer": details.site + "/novel-list",
                    "Alt-Used": "www.mtlnovel.com",
                ]

                let html = try await URLUtils.fetchContent(
                    from: details.site + path,
                    headers: headers
                )
                let htmlAsDocument = try SwiftSoup.parse(html)

                let title = try htmlAsDocument.select("h1.entry-title").text()
                let coverURL = try htmlAsDocument.select(".nov-head > amp-img").attr("src")

                var summary: [String] = []
                let paragraphs = try htmlAsDocument.select("div.desc > p")
                for paragraph in paragraphs {
                    let paragraphHtml = try paragraph.html()

                    let summaryLines = paragraphHtml.components(separatedBy: "<br />")
                    for summaryLine in summaryLines {
                        summary.append(try SwiftSoup.parse(summaryLine).text())
                    }
                }

                let genres = try htmlAsDocument.select("#genre").eachText()[0]
                    .split(separator: ", ")
                    .map(String.init)
                let authors = try htmlAsDocument.select("#author").eachText()[0]
                    .split(separator: ", ")
                    .map(String.init)
                let status = try htmlAsDocument.select("#status").text()

                let chapterListHTML = try await URLUtils.fetchContent(
                    from: details.site + path + "chapter-list/",
                    headers: headers
                )
                let chapterListAsDocument = try SwiftSoup.parse(chapterListHTML)
                let chapterElements = try chapterListAsDocument.select("a.ch-link").enumerated().reversed()
                let chapters = try chapterElements.map { chapterIndex, chapterElement in
                    let chapterPath = (try chapterElement.attr("href")).replacingOccurrences(of: details.site, with: "")
                    let chapterTitle = try chapterElement.text()
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
                    status: status,
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
                let html = try await URLUtils.fetchContent(
                    from: details.site + path,
                    headers: [
                        "Alt-Used": "www.mtlnovel.com",
                    ]
                )
                let htmlAsDocument = try SwiftSoup.parse(html)

                let txt = try htmlAsDocument.select("div.par")
                let content = try txt.select("p").eachText()

                return content
            } catch {
                throw NovelError.parse(description: "Error parsing novel chapter '\(path)': \(error.localizedDescription)")
            }
        }
    }
}
