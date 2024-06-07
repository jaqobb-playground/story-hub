import Alamofire
import Foundation
import SwiftSoup

extension NovelProvider.Implementation {
    static let MTLNovel = MTLNovelNovelProvider()

    class MTLNovelNovelProvider: NovelProvider.Implementation {
        fileprivate init() {
            super.init(
                provider: .mtlNovel,
                details: NovelProvider.Details(
                    name: "MTL Novel",
                    site: "https://www.mtlnovel.com"
                )
            )
        }

        override func fetchNovels(searchTerm: String) async throws -> [NovelPreview] {
            let response = await AF.request(
                "\(details.site)/wp-admin/admin-ajax.php?action=autosuggest&q=\(searchTerm)&__amp_source_origin=https%3A%2F%2Fwww.mtlnovel.com",
                method: .post,
                headers: [
                    "Alt-Used": "www.mtlnovel.com",
                ]
            )
            .serializingString()
            .response

            if let error = response.error {
                throw error
            }

            let data = try JSONSerialization.jsonObject(with: response.value!.data(using: .utf8)!, options: []) as! [String: Any]

            var novelPreviews: [NovelPreview] = []

            let items = data["items"] as! [Any]
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
        }

        override func parseNovel(path: String) async throws -> Novel {
            let response = await AF.request(
                "\(details.site)\(path)",
                headers: [
                    "Referer": "\(details.site)/novel-list",
                    "Alt-Used": "www.mtlnovel.com",
                ]
            )
            .serializingString()
            .response

            if let error = response.error {
                throw error
            }

            let document = try SwiftSoup.parse(response.value!)

            let title = try document.select("h1.entry-title").text()
            let coverURL = try document.select(".nov-head > amp-img").attr("src")

            var summary: [String] = []
            let paragraphs = try document.select("div.desc > p")
            for paragraph in paragraphs {
                let paragraphHtml = try paragraph.html()

                let summaryLines = paragraphHtml.components(separatedBy: "<br />")
                for summaryLine in summaryLines {
                    summary.append(try SwiftSoup.parse(summaryLine).text())
                }
            }

            let genres = (try? document.select("#genre").eachText().first?
                .split(separator: ", ")
                .map(String.init)) ?? []
            let authors = (try? document.select("#author").eachText().first?
                .split(separator: ", ")
                .map(String.init)) ?? []
            let status = try document.select("#status").text()

            let chapterListResponse = await AF.request(
                details.site + path + "chapter-list/",
                headers: [
                    "Referer": details.site + "/novel-list",
                    "Alt-Used": "www.mtlnovel.com",
                ]
            )
            .serializingString()
            .response

            if let error = chapterListResponse.error {
                throw error
            }

            let chapterListDocument = try SwiftSoup.parse(chapterListResponse.value!)

            let chapterElements = try chapterListDocument.select("a.ch-link").enumerated().reversed()
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
        }

        override func parseNovelChapter(path: String) async throws -> [String] {
            let response = await AF.request(
                "\(details.site)\(path)",
                headers: [
                    "Alt-Used": "www.mtlnovel.com",
                ]
            )
            .serializingString()
            .response

            if let error = response.error {
                throw error
            }

            let document = try SwiftSoup.parse(response.value!)

            let txt = try document.select("div.par")
            let content = try txt.select("p").eachText()

            return content
        }
    }
}
