//
//  StubPostManager.swift
//  Bragit
//
//  Created by seongjun cho on 8/22/25.
//

import Foundation

import Supabase
import RxSwift

class StubPostManager: PostManagerProtocol {
  func rxFetchPosts(ids: [String]) -> RxSwift.Observable<[Post]> {
    return .just(Self.samplePosts)
  }

  func rxFetchPostByAuthorId(authorId: String, from: Int, to: Int) -> RxSwift.Observable<[Post]> {
    return .just(Self.samplePosts)
  }

  func fetchPopularPost(from: Int, to: Int) async throws -> [Post] {
    return Self.samplePosts
  }

  func rxFetchPopularPost(from: Int, to: Int) -> RxSwift.Observable<[Post]> {
    return .just(Self.samplePosts)
  }

  func rxSearchFollowUserPost(followIds: [String], from: Int, to: Int) -> RxSwift.Observable<[Post]> {
    return .just(Self.samplePosts)
  }

  func searchFeed(tagIDs: [String], from: Int, to: Int) async throws -> [Post] {
    return Self.samplePosts
  }

  func rxSearchFeed(tagIDs: [String], from: Int, to: Int) -> RxSwift.Observable<[Post]> {
    return .just(Self.samplePosts)
  }

  // 모든 함수에서 일관된 데이터를 사용하기 위한 정적 샘플 데이터입니다.
  static let samplePosts: [Post] = [
    Post(
      title: "SwiftUI 마스터하기: 선언적 UI의 모든 것",
      thumbnailImage: "https://picsum.photos/200/300",
      author: Author(id: UUID().uuidString, nickname: "SwiftUI-Pro", profile: nil),
      tags: [
        Tag(id: UUID().uuidString, tag: "iOS", count: 25),
        Tag(id: UUID().uuidString, tag: "SwiftUI", count: 18)],
      content: """
        SwiftUI는 Apple의 최신 UI 프레임워크입니다.
        선언적 구문을 통해 어떻게 더 빠르고 직관적으로 아름다운 UI를 만들 수 있는지 알아봅니다.
        이 글에서는 State, Binding, ObservableObject 등 핵심 개념을 다룹니다.
      """,
      like: 42,
      commentCount: 8,
      description: "SwiftUI의 핵심 개념을 파헤쳐봅시다."
    ),
    Post(
      title: "React Hooks는 함수형 컴포넌트의 기능, React Hooks 완벽 정복 React Hooks 완벽 정복React Hooks 완벽 정복",
      author: Author(id: UUID().uuidString, nickname: "React-Master", profile: nil),
      tags: [
        Tag(id: UUID().uuidString, tag: "Web", count: 30),
        Tag(id: UUID().uuidString, tag: "Web", count: 30),
        Tag(id: UUID().uuidString, tag: "Weㄴㄴㄴㄴㄴㄴㄴㅇㅇㅇㅇㅇㅇㅇㄴㄴㄴ", count: 30),
        Tag(id: UUID().uuidString, tag: "Web", count: 30),
        Tag(id: UUID().uuidString, tag: "Web", count: 30),
        Tag(id: UUID().uuidString, tag: "Web", count: 30),
        Tag(id: UUID().uuidString, tag: "Web", count: 30),
        Tag(id: UUID().uuidString, tag: "Web", count: 30),
        Tag(id: UUID().uuidString, tag: "Web", count: 30),
        Tag(id: UUID().uuidString, tag: "Web", count: 30),
        Tag(id: UUID().uuidString, tag: "Web", count: 30),
        Tag(id: UUID().uuidString, tag: "Web", count: 30),
        Tag(id: UUID().uuidString, tag: "Web", count: 30),
        Tag(id: UUID().uuidString, tag: "React", count: 22)],
      content: """
        useState, useEffect, useContext 등 React Hooks는 함수형 컴포넌트의 기능을 극대화합니다.
        클래스형 컴포넌트 없이도 상태 관리와 생명주기 로직을 어떻게 다룰 수 있는지 예제와 함께 설명합니다.
        """,
      like: 76,
      commentCount: 15,
      description: """
        useState, useEffect, useContext 등 React Hooks는 함수형 컴포넌트의 기능을 극대화합니다.
        클래스형 컴포넌트 없이도 상태 관리와 생명주기 로직을 어떻게 다룰 수 있는지 예제와 함께 설명합니다.
        """
    ),
    Post(
      title: "Node.js와 Express로 만드는 RESTful API",
      thumbnailImage: "https://picsum.photos/200/300",
      author: nil,
      tags: [
        Tag(id: UUID().uuidString, tag: "Web", count: 30),
        Tag(id: UUID().uuidString, tag: "NodeJS", count: 15)],
      content: """
        Node.js는 빠른 속도와 비동기 I/O 처리 능력 덕분에 백엔드 개발에서 많은 사랑을 받고 있습니다.
        Express 프레임워크를 사용하여 효율적이고 확장 가능한 RESTful API를 구축하는 방법을 단계별로 알아봅니다.
        """,
      like: 55,
      commentCount: 12,
      description: "효율적인 백엔드 API 서버를 구축하는 실전 가이드."
    ),
    Post(
      title: "클린 코드: 읽기 좋은 코드가 좋은 코드다",
      author: Author(id: UUID().uuidString, nickname: "Uncle-Bob-Fan", profile: nil),
      tags: [
        Tag(id: UUID().uuidString, tag: "Programming", count: 50),
        Tag(id: UUID().uuidString, tag: "CleanCode", count: 20)],
      content: """
        소프트웨어는 한 번 작성하고 끝나는 것이 아니라, 계속해서 읽고 유지보수해야 합니다.
        의미 있는 이름 짓기, 간결한 함수 작성법, 적절한 주석 사용법 등 동료 개발자들이 사랑하는 코드를 작성하는 비결을 공유합니다.
        """,
      like: 102,
      commentCount: 25,
      description: "유지보수하기 쉬운 코드를 작성하는 원칙과 실제."
    ),
    Post(
      title: "애자일(Agile)과 스크럼(Scrum) 실전 도입기",
      author: Author(id: UUID().uuidString, nickname: "PM_Hero", profile: nil),
      tags: [
        Tag(id: UUID().uuidString, tag: "Agile", count: 15),
        Tag(id: UUID().uuidString, tag: "Scrum", count: 13)],
      content: """
        변화에 빠르게 대응하고 고객 가치를 지속적으로 전달하는 애자일 방법론.
        우리 팀이 어떻게 스크럼을 도입하여 개발 프로세스를 개선하고 팀워크를 강화했는지,
        그 과정에서 겪은 어려움과 해결책을 나눕니다.
        """,
      like: 35,
      commentCount: 9,
      description: "우리 팀의 개발 문화를 바꾼 애자일과 스크럼 도입 이야기."
    )
  ]

  // 메인 피드 게시글 가져오기
  func fetchMainFeedData(from: Int, to: Int) async throws -> [Post] {
    return Self.samplePosts
  }

  func rxFetchMainFeedData(from: Int, to: Int) -> Observable<[Post]> {
    return .just(Self.samplePosts)
  }

  // 태그 id로 게시글 가져오기
  func searchFeed(tagID: String) async throws -> [Post] {
    return Self.samplePosts.filter { post in
      post.tags.contains { $0.id == tagID }
    }
  }

  // 태그 검색
  func searchTags(searchText: String) async throws -> [Tag] {
    return Self.samplePosts.first!.tags
  }

  // 게시글 검색
  func searchPosts(searchText: String) async throws -> [Post] {
    return Self.samplePosts
  }

  // 썸네일 이미지 업로드
  func uploadImage(data: Data, fileName: String, folder: String) async throws -> URL {
    // 뭐하는 코드? → 프로토콜 충족용. 네트워크 업로드 없이 테스트 가능한 URL 생성
    return URL(string: "https://picsum.photos/seed/\(UUID().uuidString)/600/400")!
  }

  func rxUploadImage(data: Data, fileName: String, folder: String) -> Observable<URL> {
    let url = URL(string: "https://picsum.photos/seed/\(UUID().uuidString)/600/400")!
    return .just(url)
  }

  // 본문 이미지 업로드
  func uploadImages(datas: [Data], folder: String) async throws -> [URL] {
    return try await withCheckedThrowingContinuation { continuation in
      let urls = (0..<datas.count).map { _ in
        URL(string: "https://picsum.photos/seed/\(UUID().uuidString)/800/600")!
      }
      continuation.resume(returning: urls)
    }
  }

  func rxUploadImages(datas: [Data], folder: String) -> Observable<[URL]> {
    let urls = (0..<datas.count).map { _ in
      URL(string: "https://picsum.photos/seed/\(UUID().uuidString)/800/600")!
    }
    return .just(urls)
  }

  func createPost(
    postId: String,
    authorId: String,
    title: String,
    description: String,
    thumbnailURL: URL?,
    archivedContent: Data) async throws -> Post {
      let author = Author(id: authorId, nickname: nil, profile: nil)
      let post = Post(
        id: UUID(uuidString: postId) ?? UUID(),
        title: title,
        thumbnailImage: thumbnailURL?.absoluteString,
        author: author,
        date: Date(),
        tags: [],
        content: "[archived:",
        like: 0,
        reports: 0,
        commentCount: 0,
        description: description
      )
      return post
    }

  func rxCreatePost(
    postId: String,
    authorId: String,
    title: String,
    description: String,
    thumbnailURL: URL?,
    archivedContent: Data) -> RxSwift.Observable<Post> {
      let author = Author(id: authorId, nickname: nil, profile: nil)
      let post = Post(
        id: UUID(uuidString: postId) ?? UUID(),
        title: title,
        thumbnailImage: thumbnailURL?.absoluteString,
        author: author,
        date: Date(),
        tags: [],
        content: "[archived:",
        like: 0,
        reports: 0,
        commentCount: 0,
        description: description
      )
      return .just(post)
    }

  func attachTags(postId: String, tagIds: [String]) async throws {
    _ = (postId, tagIds)
    return
  }

  func rxAttachTags(postId: String, tagIds: [String]) -> RxSwift.Observable<Void> {
    _ = (postId, tagIds)
    return .just(())
  }

  func incrementLike(postId: String, delta: Int) async throws -> Int {
    let baseLikes = 50
    return baseLikes + delta
  }

  func rxIncrementLike(postId: String, delta: Int) -> RxSwift.Observable<Int> {
    let baseLikes = 50
    let newLikes = baseLikes + delta
    return .just(newLikes)
  }

  func deletePost(postId: String) async throws {
    _ = postId
  }

  func rxDeletePost(postId: String) -> RxSwift.Observable<Void> {
    _ = postId
    return .just(())
  }
}
