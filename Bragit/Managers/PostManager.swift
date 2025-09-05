//
//  PostManager.swift
//  Bragit
//
//  Created by seongjun cho on 8/20/25.
//

import Foundation

import Supabase
import RxSwift
import Dependencies

protocol PostManagerProtocol {
  func fetchMainFeedData(from: Int, to: Int) async throws -> [Post]
  func searchFeed(tagID: String) async throws -> [Post]
  func searchFeed(tagIDs: [String], from: Int, to: Int) async throws -> [Post]
  func searchPosts(searchText: String) async throws -> [Post]
  func rxFetchMainFeedData(from: Int, to: Int) -> Observable<[Post]>
  func rxSearchFeed(tagIDs: [String], from: Int, to: Int) -> Observable<[Post]>
  func rxSearchFollowUserPost(followIds: [String], from: Int, to: Int) -> Observable<[Post]>
  func fetchPopularPost(from: Int, to: Int) async throws -> [Post]
  func rxFetchPopularPost(from: Int, to: Int) -> Observable<[Post]>
  func rxFetchPostByAuthorId(authorId: String, from: Int, to: Int) -> Observable<[Post]>
  func uploadImage(data: Data, fileName: String, folder: String) async throws -> URL
  func rxUploadImage(data: Data, fileName: String, folder: String) -> Observable<URL>
  func uploadImages(datas: [Data], folder: String) async throws -> [URL]
  func rxUploadImages(datas: [Data], folder: String) -> Observable<[URL]>
  func createPost(
    postId: String,
    authorId: String,
    title: String,
    description: String,
    thumbnailURL: URL?,
    archivedContent: Data
  ) async throws -> Post
  func rxCreatePost(
    postId: String,
    authorId: String,
    title: String,
    description: String,
    thumbnailURL: URL?,
    archivedContent: Data
  ) -> Observable<Post>
  func attachTags(postId: String, tagIds: [String]) async throws
  func rxAttachTags(postId: String, tagIds: [String]) -> Observable<Void>
  func incrementLike(postId: String, delta: Int) async throws -> Int
  func rxIncrementLike(postId: String, delta: Int) -> Observable<Int>
  func deletePost(postId: String) async throws
  func rxDeletePost(postId: String) -> Observable<Void>
}

class PostManager: PostManagerProtocol {
  @Dependency(\.supabase) var client

  private let bucketName: String = "post-images"

  // 메인 피드 게시글 가져오기
  func fetchMainFeedData(from: Int, to: Int) async throws -> [Post] {
    var post = [Post]()

    post = try await client
      .from("Post")
      .select("*, Tag(*), comment_count:Comment(count), User_Info(id, nickname, profile)")
      .range(from: from, to: to)
      .order("date", ascending: false)
      .execute()
      .value

    return post
  }

  func rxFetchMainFeedData(from: Int, to: Int) -> Observable<[Post]> {
    .create { [weak self] observer in
      guard let self = self else {
        observer.onCompleted()
        return Disposables.create()
      }

      Task {
        do {
          let posts = try await self.fetchMainFeedData(
            from: from,
            to: to
          )
          observer.onNext(posts)
          observer.onCompleted()
        } catch {
          observer.onError(error)
        }
      }

      return Disposables.create()
    }
  }

  // 태그 id로 게시글 가져오기
  func searchFeed(tagID: String) async throws -> [Post] {
    let posts: [Post] = try await client
      .from("Post")
      .select("*, Tag(*), comment_count:Comment(count), post_tags!inner(*), User_Info(id, nickname, profile)")
      .eq("post_tags.tag_id", value: tagID)
      .execute()
      .value

    return posts
  }

  // 태그 id들로 게시글 가져오기
  func searchFeed(tagIDs: [String], from: Int, to: Int) async throws -> [Post] {
    let posts: [Post] = try await client
      .from("Post")
      .select("*, Tag(*), comment_count:Comment(count), post_tags!inner(*), User_Info(id, nickname, profile)")
      .in("post_tags.tag_id", values: tagIDs)
      .order("date", ascending: false)
      .range(from: from, to: to)
      .execute()
      .value

    return posts
  }

  func rxSearchFeed(tagIDs: [String], from: Int, to: Int) -> Observable<[Post]> {
    .create { [weak self] observer in
      guard let self = self else {
        observer.onCompleted()
        return Disposables.create()
      }

      Task {
        do {
          let posts = try await self.searchFeed(
            tagIDs: tagIDs,
            from: from,
            to: to
          )
          observer.onNext(posts)
          observer.onCompleted()
        } catch {
          print(error)
          observer.onError(error)
        }
      }

      return Disposables.create()
    }
  }

  // 팔로우한 유저의 게시글 가져오기
  func rxSearchFollowUserPost(followIds: [String], from: Int, to: Int) -> Observable<[Post]> {
    .create { [weak self] observer in
      guard let self = self else {
        observer.onCompleted()
        return Disposables.create()
      }

      Task {
        do {
          let posts: [Post] = try await self.client
            .from("Post")
            .select("*, Tag(*), comment_count:Comment(count), post_tags!inner(*), User_Info(id, nickname, profile)")
            .in("author_id", values: followIds)
            .order("date", ascending: false)
            .range(from: from, to: to)
            .execute()
            .value
          observer.onNext(posts)
          observer.onCompleted()
        } catch {
          observer.onError(error)
        }
      }

      return Disposables.create()
    }
  }

  // 게시글 검색
  func searchPosts(searchText: String) async throws -> [Post] {
    async let postsWithMatchingContent: [Post] = try client
      .from("Post")
      .select("*, Tag(*), comment_count:Comment(count), User_Info(id, nickname, profile)")
      .or("title.ilike.%\(searchText)%, content.ilike.%\(searchText)%, description.ilike.*\(searchText)*")
      .execute()
      .value

    async let postsWithMatchingTag: [Post] = try client
      .from("Post")
      .select("*, Tag!inner(*), comment_count:Comment(count), User_Info(id, nickname, profile)")
      .ilike("Tag.tag", pattern: "%\(searchText)%")
      .execute()
      .value

    let (contentResults, tagResults) = try await (postsWithMatchingContent, postsWithMatchingTag)
    let allPosts = contentResults + tagResults

    var uniquePosts = [UUID: Post]()
    for post in allPosts {
      uniquePosts[post.id] = post
    }

    return Array(uniquePosts.values)
  }

  // 인기 게시글 가져오기
  func fetchPopularPost(from: Int, to: Int) async throws -> [Post] {
    let posts: [Post] = try await client
      .from("Post")
      .select("*, Tag(*), comment_count:Comment(count), post_tags!left(*), User_Info(id, nickname, profile)")
      .order("like", ascending: false)
      .range(from: from, to: to)
      .execute()
      .value

    return posts
  }

  func rxFetchPopularPost(from: Int, to: Int) -> Observable<[Post]> {
    .create { [weak self] observer in
      guard let self = self else {
        observer.onCompleted()
        return Disposables.create()
      }

      Task {
        do {
          let posts = try await self.fetchPopularPost(
            from: from,
            to: to
          )
          observer.onNext(posts)
          observer.onCompleted()
        } catch {
          print(error)
          observer.onError(error)
        }
      }

      return Disposables.create()
    }
  }

  // author id로 게시글 가져오기
  func rxFetchPostByAuthorId(authorId: String, from: Int, to: Int) -> Observable<[Post]> {
    .create { [weak self] observer in
      guard let self = self else {
        observer.onCompleted()
        return Disposables.create()
      }

      Task {
        do {
          let posts: [Post] = try await self.client
            .from("Post")
            .select("*, Tag(*), comment_count:Comment(count), post_tags!inner(*), User_Info(id, nickname, profile)")
            .eq("author_id", value: authorId)
            .order("date", ascending: false)
            .range(from: from, to: to)
            .execute()
            .value
          observer.onNext(posts)
          observer.onCompleted()
        } catch {
          observer.onError(error)
        }
      }

      return Disposables.create()
    }
  }

  private func publicURL(for path: String) throws -> URL {
    let url = try client.storage
      .from(bucketName)
      .getPublicURL(path: path)
    return url
  }

  // 썸네일 이미지 업로드
  func uploadImage(data: Data, fileName: String, folder: String) async throws -> URL {
    let path = "\(folder)/\(UUID().uuidString)-\(fileName).jpg"

    _ = try await client.storage
      .from(bucketName)
      .upload(
        path,
        data: data,
        options: FileOptions(contentType: "image/jpeg", upsert: false)
      )

    let publicURL = try publicURL(for: path)
    return publicURL
  }

  func rxUploadImage(data: Data, fileName: String, folder: String) -> Observable<URL> {
    .create { [weak self] observer in
      guard let self else {
        observer.onCompleted()
        return Disposables.create()
      }
      Task {
        do {
          let url = try await self.uploadImage(data: data, fileName: fileName, folder: folder)
          observer.onNext(url)
          observer.onCompleted()
        } catch {
          observer.onError(error)
        }
      }
      return Disposables.create()
    }
  }

  // 본문 이미지 업로드
  func uploadImages(datas: [Data], folder: String) async throws -> [URL] {
    var urls: [URL] = []
    urls.reserveCapacity(datas.count)
    for (index, data) in datas.enumerated() {
      let url = try await uploadImage(data: data, fileName: "image\(index)", folder: folder)
      urls.append(url)
    }
    return urls
  }

  func rxUploadImages(datas: [Data], folder: String) -> Observable<[URL]> {
    .create { [weak self] observer in
      guard let self else {
        observer.onCompleted()
        return Disposables.create()
      }
      Task {
        do {
          let urls = try await self.uploadImages(datas: datas, folder: folder)
          observer.onNext(urls)
          observer.onCompleted()
        } catch {
          observer.onError(error)
        }
      }
      return Disposables.create()
    }
  }

  // 게시글 생성
  func createPost(
    postId: String,
    authorId: String,
    title: String,
    description: String,
    thumbnailURL: URL?,
    archivedContent: Data
  ) async throws -> Post {
    let payload: [String: Any?] = [
      "id": postId,
      "title": title,
      "thumbnail_image": thumbnailURL?.absoluteString,
      "author_id": authorId,
      "content": archivedContent.base64EncodedString(),
      "description": description,
    ]

    let encodable = try JSONSerialization.data(withJSONObject: payload.compactMapValues { $0 })
    let json = try JSONDecoder().decode([String:String].self, from: encodable)

    let saved: Post = try await client
      .from("Post")
      .insert(json, returning: .representation)
      .select()
      .single()
      .execute()
      .value

    return saved
  }

  func rxCreatePost(
    postId: String,
    authorId: String,
    title: String,
    description: String,
    thumbnailURL: URL?,
    archivedContent: Data
  ) -> Observable<Post> {
    .create { [weak self] observer in
      guard let self else {
        observer.onCompleted()
        return Disposables.create()
      }

      Task {
        do {
          let post = try await self.createPost(
            postId: postId,
            authorId: authorId,
            title: title,
            description: description,
            thumbnailURL: thumbnailURL,
            archivedContent: archivedContent
          )
          observer.onNext(post)
          observer.onCompleted()
        } catch {
          observer.onError(error)
        }
      }

      return Disposables.create()
    }
  }

  // 게시글-태그 매핑 저장
  func attachTags(postId: String, tagIds: [String]) async throws {
    guard !tagIds.isEmpty else { return }
    let rows: [[String: String]] = tagIds.map { ["post_id": postId, "tag_id": $0] }

    do {
      _ = try await client
        .from("post_tags")
        .insert(rows, returning: .minimal)
        .execute()
    } catch {

      throw error
    }
  }

  func rxAttachTags(postId: String, tagIds: [String]) -> Observable<Void> {
    .create { [weak self] observer in
      guard let self else {
        observer.onCompleted()
        return Disposables.create()
      }
      Task {
        do {
          try await self.attachTags(postId: postId, tagIds: tagIds)
          observer.onNext(())
          observer.onCompleted()
        } catch {
          observer.onError(error)
        }
      }

      return Disposables.create()
    }
  }

  // 좋아요 증가/감소
  func incrementLike(postId: String, delta: Int) async throws -> Int {
    let newCount: Int = try await client
      .rpc("inc_post_like", params: IncPostLikeParams(p_post_id: postId, p_delta: delta))
      .execute()
      .value
    return newCount
  }

  func rxIncrementLike(postId: String, delta: Int) -> Observable<Int> {
    .create { [weak self] observer in
      guard let self else {
        observer.onCompleted()
        return Disposables.create()
      }
      Task {
        do {
          let newCount = try await self.incrementLike(postId: postId, delta: delta)
          observer.onNext(newCount)
          observer.onCompleted()
        } catch {
          observer.onError(error)
        }
      }
      return Disposables.create()
    }
  }

  // 게시물 삭제
  func deletePost(postId: String) async throws {
    _ = try await client
      .from("Post")
      .delete()
      .eq("id", value: postId)
      .execute()
  }

  func rxDeletePost(postId: String) -> Observable<Void> {
    .create { [weak self] observer in
      guard let self else { observer.onCompleted(); return Disposables.create() }
      Task {
        do {
          try await self.deletePost(postId: postId)
          observer.onNext(())
          observer.onCompleted()
        } catch {
          observer.onError(error)  // 0행인 경우도 여기로 떨어짐
        }
      }
      return Disposables.create()
    }
  }
}

extension PostManager {
  // inc_post_like 함수에 넘겨줄 RPC 파라미터 정의
  private struct IncPostLikeParams: Encodable, Sendable {
    let p_post_id: String
    let p_delta: Int
  }
}

