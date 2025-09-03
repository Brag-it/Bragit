//
//  Post.swift
//  Bragit
//
//  Created by seongjun cho on 8/20/25.
//

import Foundation

struct Post: Identifiable, Codable, Hashable {
  static func == (lhs: Post, rhs: Post) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  let id: UUID                     // 게시글 ID (PK)
  let title: String                // 제목
  let thumbnailImage: String?      // 썸네일
  var author: Author?              // 작성자
  let date: Date                   // 작성일자
  let tags: [Tag]                  // 태그
  let content: String               // 내용
  var like: Int                    // 좋아요 수
  var reports: Int                 // 신고 수
  var commentCount: Int            // 댓글 수
  let description: String          // 미리보기 글

  enum CodingKeys: String, CodingKey {
    case id
    case title
    case thumbnailImage = "thumbnail_image"
    case author = "User_Info"
    case date
    case tags = "Tag"
    case content
    case like
    case reports
    case commentCount = "comment_count"
    case description
  }

  private struct CommentCountWrapper: Codable {
    let count: Int
  }

  init(
    id: UUID = UUID(),
    title: String,
    thumbnailImage: String? = nil,
    author: Author?,
    date: Date = Date(),
    tags: [Tag] = [],
    content: String,
    like: Int = 0,
    reports: Int = 0,
    commentCount: Int = 0,
    description: String = ""
  ) {
    self.id = id
    self.title = title
    self.thumbnailImage = thumbnailImage
    self.author = author
    self.date = date
    self.tags = tags
    self.content = content
    self.like = like
    self.reports = reports
    self.commentCount = commentCount
    self.description = description
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(UUID.self, forKey: .id)
    title = try container.decode(String.self, forKey: .title)
    thumbnailImage = try container.decodeIfPresent(String.self, forKey: .thumbnailImage)
    author = try container.decodeIfPresent(Author.self, forKey: .author)
    date = try container.decode(Date.self, forKey: .date)
    tags = try container.decode([Tag].self, forKey: .tags)
    content = try container.decode(String.self, forKey: .content)
    like = try container.decode(Int.self, forKey: .like)
    reports = try container.decode(Int.self, forKey: .reports)
    description = try container.decode(String.self, forKey: .description)

    let commentCountWrappers = try container.decode([CommentCountWrapper].self, forKey: .commentCount)
    commentCount = commentCountWrappers.first?.count ?? 0
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(title, forKey: .title)
    try container.encodeIfPresent(thumbnailImage, forKey: .thumbnailImage)
    try container.encodeIfPresent(author, forKey: .author)
    try container.encode(date, forKey: .date)
    try container.encode(tags, forKey: .tags)
    try container.encode(content, forKey: .content)
    try container.encode(like, forKey: .like)
    try container.encode(reports, forKey: .reports)
    try container.encode(description, forKey: .description)
    let commentCountWrappers = [CommentCountWrapper(count: commentCount)]
    try container.encode(commentCountWrappers, forKey: .commentCount)
  }
}

struct Tag: Identifiable, Codable, Hashable {
  let id: String
  let tag: String
  let count: Int
}

struct Author: Codable, Hashable {
  let id: String
  let nickname: String?
  let profile: String?
}
