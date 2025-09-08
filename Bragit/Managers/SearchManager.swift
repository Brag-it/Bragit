//
//  SearchManager.swift
//  Bragit
//
//  Created by 이태윤 on 9/8/25.
//
import Foundation

import Supabase
import RxSwift
import Dependencies

// 검색 결과 번들
struct SearchBundle {
  let tags: [Tag]
  let posts: [Post]
  let users: [User]
}

protocol SearchManagerProtocol {
  func searchAll(searchText: String, page: Int, pageSize: Int) async throws -> SearchBundle
  func rxSearchAll(searchText: String, page: Int, pageSize: Int) -> Observable<SearchBundle>
}

final class SearchManager: SearchManagerProtocol {
  @Dependency(\.supabase) var client

  func searchAll(searchText: String, page: Int, pageSize: Int) async throws -> SearchBundle {
    // 페이지 계산
    let start = page * pageSize
    let end = start + pageSize - 1

    // 태그
    async let tagRows: [Tag] = try client
      .from("Tag")
      .select("*")
      .ilike("tag", pattern: "%\(searchText)%")
      .range(from: start, to: end)
      .execute()
      .value

    // 게시글
    async let postsByContent: [Post] = try client
      .from("Post")
      .select("*, Tag(*), comment_count:Comment(count), User_Info(id, nickname, profile)")
      .or("title.ilike.%\(searchText)%,content.ilike.%\(searchText)%,description.ilike.%\(searchText)%")
      .range(from: start, to: end)
      .execute()
      .value

    async let postsByTag: [Post] = try client
      .from("Post")
      .select("*, Tag!inner(*), comment_count:Comment(count), User_Info(id, nickname, profile)")
      .ilike("Tag.tag", pattern: "%\(searchText)%")
      .range(from: start, to: end)
      .execute()
      .value

    // 사용자
    async let userRows: [User] = try client
      .from("User_Info")
      .select("*")
      .ilike("nickname", pattern: "%\(searchText)%")
      .range(from: start, to: end)
      .execute()
      .value

    let (tags, contentPosts, tagPosts, users) = try await (tagRows, postsByContent, postsByTag, userRows)
    // 게시글 중복 제거
    var uniquePostMap: [UUID: Post] = [:]
    (contentPosts + tagPosts).forEach { uniquePostMap[$0.id] = $0 }
    let uniquePosts = Array(uniquePostMap.values)

    return SearchBundle(tags: tags, posts: uniquePosts, users: users)
  }

  func rxSearchAll(searchText: String, page: Int, pageSize: Int) -> Observable<SearchBundle> {
    .create { [weak self] observer in
      guard let self else { observer.onCompleted(); return Disposables.create() }
      let task = Task {
        do {
          let bundle = try await self.searchAll(searchText: searchText, page: page, pageSize: pageSize)
          observer.onNext(bundle)
          observer.onCompleted()
        } catch {
          observer.onError(error)
        }
      }
      return Disposables.create { task.cancel() }
    }
  }
}
