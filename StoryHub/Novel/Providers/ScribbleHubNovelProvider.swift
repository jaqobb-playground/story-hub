import Alamofire
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
                    site: "https://www.scribblehub.com"
                )
            )
        }

        override func fetchNovels(searchTerm: String) async throws -> [NovelPreview] {
            let response = await AF.request(
                "\(details.site)/?s=\(searchTerm)&post_type=fictionposts",
                method: .post
            )
            .serializingString()
            .response

            if let error = response.error {
                throw error
            }

            let document = try SwiftSoup.parse(response.value!)

            return try document.select(".search_main_box")
                .array()
                .map { element -> NovelPreview in
                    let path = (try element.select(".search_title > a").attr("href"))
                        .replacingOccurrences(of: details.site, with: "")
                    let title = try element.select(".search_title > a").text()
                    let coverURL = try element.select(".search_img > img").attr("src")

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
            let response = await AF.request("\(details.site)\(path)?toc=-1#content1")
                .serializingString()
                .response

            if let error = response.error {
                throw error
            }

            let document = try SwiftSoup.parse(response.value!)

            let title = try document.select(".fic_title").attr("title")
            let coverURL = try document.select(".fic_image > img").attr("src")
            let summary = try document.select(".wi_fic_desc > p").eachText()
            let genres = try document.select(".fic_genre")
                .enumerated()
                .map { _, genreElement in
                    try genreElement.text()
                }
            let authors = [try document.select(".auth_name_fic").text()]
            var status = try document.select(".rnd_stats").last()?.nextElementSibling()?.text()
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

            let chapterElements = try document.select(".wi_fic_table > .toc_ol > .toc_w").enumerated().reversed()
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
        }

        override func parseNovelChapter(path: String) async throws -> [String] {
            let response = await AF.request("\(details.site)\(path)")
                .serializingString()
                .response

            if let error = response.error {
                throw error
            }

            let document = try SwiftSoup.parse(response.value!)

            let txt = try document.select("div.chp_raw")
            let content = try txt.select("p").eachText()

            return content
        }
    }
}
