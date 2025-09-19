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
  func rxDecrementTagCount(tagName: String) -> Observable<Int>
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

  func rxDecrementTagCount(tagName: String) -> Observable<Int> {
    return Observable.create { observer in
      Task {
        do {
          // 태그 카운트를 감소시키는 DB 함수 호출
          let response = try await self.client
            .rpc("decrement_tag_count", params: ["tag_input": tagName])
            .execute()

          let rawData = response.data
          var finalCount: Int?

          // DB 함수의 응답이 JSON 배열 형태일 경우 파싱
          if let jsonArray = try? JSONSerialization.jsonObject(with: rawData, options: []) as? [[String: Any]],
             let count = jsonArray.first?["count"] as? Int
          {
            finalCount = count
          }
          // DB 함수의 응답이 일반 텍스트 형태일 경우 파싱
          else if let countString = String(data: rawData, encoding: .utf8), let count = Int(countString) {
            finalCount = count
          }

          if let count = finalCount {
            // 태그 카운트가 1 이상이면 유지하고, 0이 되면 삭제
            if count >= 1 {
              observer.onNext(count)
              observer.onCompleted()
            } else {
              // 카운트가 0 태그 삭제 로직 실행
              let deleteResponse = try await self.client
                .from("Tag")
                .delete()
                .eq("tag", value: tagName)
                .execute()

              // HTTP 상태 코드로 성공 여부 확인
              if (200 ..< 300).contains(deleteResponse.status) {
                observer.onNext(0) // 0을 보내 삭제되었음을 알림
                observer.onCompleted()
              } else {
                let error = NSError(domain: "Delete failed", code: deleteResponse.status)
                print("🔥 [태그 삭제 실패] status: \(deleteResponse.status)")
                observer.onError(error)
              }
            }
          } else {
            let error = NSError(domain: "Invalid response format", code: 0)
            print("🚨 응답 데이터 포맷 오류: \(String(data: rawData, encoding: .utf8) ?? "Invalid data")")
            observer.onError(error)
          }
        } catch {
          print("🔥 [태그 감소 or 삭제 실패] \(error.localizedDescription)")
          observer.onError(error)
        }
      }

      return Disposables.create()
    }
  }
}
