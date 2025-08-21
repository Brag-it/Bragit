//
//  Post.swift
//  Bragit
//
//  Created by seongjun cho on 8/20/25.
//

import Foundation

struct Post: Identifiable, Codable {
  let id: UUID                     // 게시글 ID (PK)
  var title: String                // 제목
  var thumbnailImage: String?      // 썸네일
  var authorId: UUID?              // 작성자 ID (FK) nil 일시 탈퇴한 유저
  var date: Date                   // 작성일자
  var tags: [Tag]                  // 태그
  var detail: String               // 내용
  var like: Int                    // 좋아요 수
  var reports: Int                 // 신고 수
  var commentCount: Int            // 댓글 수
  var description: String          // 미리보기 글

  enum CodingKeys: String, CodingKey {
    case id
    case title
    case thumbnailImage = "thumbnail_image"
    case authorId = "author_id"
    case date
    case tags = "Tag"
    case detail
    case like
    case reports
    case commentCount = "comment_count"
    case description
  }

  private struct CommentCountWrapper: Codable {
    let count: Int
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(UUID.self, forKey: .id)
    title = try container.decode(String.self, forKey: .title)
    thumbnailImage = try container.decodeIfPresent(String.self, forKey: .thumbnailImage)
    authorId = try container.decodeIfPresent(UUID.self, forKey: .authorId)
    date = try container.decode(Date.self, forKey: .date)
    tags = try container.decode([Tag].self, forKey: .tags)
    detail = try container.decode(String.self, forKey: .detail)
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
    try container.encodeIfPresent(authorId, forKey: .authorId)
    try container.encode(date, forKey: .date)
    try container.encode(tags, forKey: .tags)
    try container.encode(detail, forKey: .detail)
    try container.encode(like, forKey: .like)
    try container.encode(reports, forKey: .reports)
    try container.encode(description, forKey: .description)
    let commentCountWrappers = [CommentCountWrapper(count: commentCount)]
    try container.encode(commentCountWrappers, forKey: .commentCount)
  }
}

struct Tag: Identifiable, Codable {
  let id: String
  var tag: String
  var count: Int
}
