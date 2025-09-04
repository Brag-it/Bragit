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
  func upsertTags(names: [String]) async throws -> [Tag]
  func rxUpsertTags(names: [String]) -> Observable<[Tag]>
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

  func upsertTags(names: [String]) async throws -> [Tag] {
    // 공백 제거 + 중복 제거
    let unique = Array(Set(
      names
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
    ))
    guard !unique.isEmpty else { return [] }

    var ensured: [Tag] = []
    ensured.reserveCapacity(unique.count)

    // 기존 태그 조회
    let existing: [Tag] = try await client
      .from("Tag")
      .select()
      .in("tag", values: unique)
      .execute()
      .value

    let existingNames = Set(existing.map { $0.tag })
    let newNames = unique.filter { !existingNames.contains($0) }

    // 태그 count += 1
    for old in existing {
      let updated: Tag = try await client
        .from("Tag")
        .update(["count": old.count + 1])
        .eq("id", value: old.id)
        .select()
        .single()
        .execute()
        .value
      ensured.append(updated)
    }

    // 신규 태그 생성
    if !newNames.isEmpty {
      let payloads: [Tag] = newNames.map { Tag(id: UUID().uuidString, tag: $0, count: 1) }
      let created: [Tag] = try await client
        .from("Tag")
        .insert(payloads, returning: .representation)
        .select()
        .execute()
        .value
      ensured.append(contentsOf: created)
    }

    return ensured
  }

  func rxUpsertTags(names: [String]) -> Observable<[Tag]> {
    .create { [weak self] observer in
      guard let self = self else {
        observer.onNext([])
        observer.onCompleted()
        return Disposables.create()
      }
      let task = Task {
        do {
          let result = try await self.upsertTags(names: names)
          observer.onNext(result)
          observer.onCompleted()
        } catch {
          observer.onError(error)
        }
      }
      return Disposables.create { task.cancel() }
    }
  }
}
