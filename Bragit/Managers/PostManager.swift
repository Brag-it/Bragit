//
//  PostManager.swift
//  Bragit
//
//  Created by seongjun cho on 8/20/25.
//

import Foundation
import Supabase

class PostManager {
  private let client: SupabaseClient

  init() {
    let apiKey = Bundle.main.infoDictionary?["Supabase api"] as? String ?? ""
    let urlString = Bundle.main.infoDictionary?["Supabase URL"] as? String ?? ""

    if apiKey.isEmpty || urlString.isEmpty {
      fatalError("⚠️ SUPABASE_API_KEY, SUPABASE_URL Config 설정 빠짐!!")
    }

    if let url = URL(string: "https://" + urlString) {
      client = SupabaseClient(supabaseURL: url, supabaseKey: apiKey)
    } else {
      fatalError("⚠️ URL 구성 오류")
    }
  }

  // 메인 피드 게시글 가져오기
  func fetchMainFeedData() async throws -> [Post] {
    var post = [Post]()

    post = try await client
      .from("Post")
      .select("*, Tag(*), comment_count:Comment(count), User_Info(id, nickname, profile)")
      .execute()
      .value

    return post
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

  // 태그 검색
  func searchTags(searchText: String) async throws -> [Tag] {
    let tags: [Tag] = try await client
      .from("Tag")
      .select()
      .ilike("tag", pattern: "%\(searchText)%")
      .execute()
      .value

    return tags
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
}
