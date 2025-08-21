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
      .select("*, Tag(*), comment_count:Comment(count)")
      .execute()
      .value

    return post
  }
}
