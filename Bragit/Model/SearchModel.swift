//
//  SearchModel.swift
//  Bragit
//
//  Created by 이태윤 on 9/8/25.
//
import UIKit

enum SearchMode {
  case recent                // 최근 검색
  case typingSuggestions     // 입력 중
  case results               // 결과
}

enum SearchScope {
  case tag
  case post
  case user
}

enum SearchSection: Int, CaseIterable {
  case recent          // 최근 검색
  case suggestions     // 입력 중
  case tagResults      // 태그 결과
  case postResults     // 게시글 결과
  case userResults     // 사용자 결과
}

enum SearchRow: Hashable {
  case recentKeyword(String)
  case suggestion(String)
  case tag(SearchTagItem)
  case post(SearchPostItem)
  case user(SearchUserItem)
}

// MARK: - Models

struct SearchTagItem: Hashable {
  let id: UUID = UUID()
  let tag: String
}

struct SearchPostItem: Hashable {
  let id: UUID = UUID()
  let post: Post
}     

struct SearchUserItem: Hashable {
  let id: UUID = UUID()
  let user: User
}
