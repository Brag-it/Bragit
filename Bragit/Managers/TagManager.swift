//
//  TagManager.swift
//  Bragit
//
//  Created by seongjun cho on 8/28/25.
//

import Foundation

import Supabase
import RxSwift
import Dependencies

protocol TagManagerProtocol {
  func fetchPopularTags() async throws -> [Tag]
  func rxFetchPopularTags() -> Observable<[Tag]>
  func searchTags(searchText: String, page: Int, pageSize: Int) async throws -> [Tag]
  func rxSearchTags(searchText: String, page: Int, pageSize: Int) -> Observable<[Tag]>
}

class TagManager: TagManagerProtocol {
  @Dependency(\.supabase) var client

  // 인기 태그 가져오기
  func fetchPopularTags() async throws -> [Tag] {
    let tags: [Tag] = try await client
      .from("Tag")
      .select()
      .order("count", ascending: false)
      .range(from: 0, to: 20)
      .execute()
      .value

    return tags
  }

  func rxFetchPopularTags() -> Observable<[Tag]> {
    .create { [weak self] observer in
      guard let self = self else {
        observer.onCompleted()
        return Disposables.create()
      }

      Task {
        do {
          let tags = try await self.fetchPopularTags()
          observer.onNext(tags)
          observer.onCompleted()
        } catch {
          observer.onError(error)
        }
      }

      return Disposables.create()
    }
  }

  // 태그 검색
  func searchTags(searchText: String, page: Int, pageSize: Int) async throws -> [Tag] {
    let start = page * pageSize
    let end = start + pageSize - 1
    let tags: [Tag] = try await client
      .from("Tag")
      .select()
      .ilike("tag", pattern: "%\(searchText)%")
      .range(from: start, to: end)
      .execute()
      .value

    return tags
  }

  func rxSearchTags(searchText: String, page: Int, pageSize: Int) -> Observable<[Tag]> {
    .create { [weak self] observer in
      guard let self = self else {
        observer.onNext([])
        observer.onCompleted()
        return Disposables.create()
      }
      let task = Task {
        do {
          let tags = try await self.searchTags(searchText: searchText, page: page, pageSize: pageSize)
          observer.onNext(tags)
          observer.onCompleted()
        } catch {
          observer.onError(error)
        }
      }

      return Disposables.create { task.cancel() }
    }
  }
}
