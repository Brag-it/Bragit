//
//  Comment.swift
//  Bragit
//
//  Created by luca on 9/8/25.
//

import Foundation

struct Comment: Encodable {
  let id: UUID
  let post_id: UUID
  let commenter_id: String
  let content: String
  let date: Date
}
