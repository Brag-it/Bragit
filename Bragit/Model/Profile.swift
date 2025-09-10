//
//  Profile.swift
//  Bragit
//
//  Created by seongjun cho on 9/2/25.
//

import Foundation

struct Profile: Hashable {
  let id: String
  let nickName: String
  let profileImage: String
  let follwerCount: Int
  let followingCount: Int
  let favoriteTagCount: Int
  let isFollowing: Bool
}
