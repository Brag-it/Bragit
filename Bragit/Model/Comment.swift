//
//  Comment.swift
//  Bragit
//
//  Created by luca on 9/8/25.
//

import Foundation

struct Comment: Encodable {
  let id: UUID
  let postId: UUID
  let commenterId: String
  let content: String
  let date: Date

  enum CodingKeys: String, CodingKey {
    case id
    case postId = "post_id"
    case commenterId = "commenter_id"
    case content
    case date
  }
}
