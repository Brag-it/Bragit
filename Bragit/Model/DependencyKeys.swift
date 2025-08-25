//
//  DependencyKeys.swift
//  Bragit
//
//  Created by seongjun cho on 8/22/25.
//

import Foundation

import Dependencies
import Supabase

enum PostDependencyKey: DependencyKey {
  static let liveValue: PostManagerProtocol = PostManager()
  static let testValue: PostManagerProtocol = StubPostManager()
  static let previewValue: PostManagerProtocol = StubPostManager()
}

enum SupabaseDependencyKey: DependencyKey {
  static let liveValue: SupabaseClient = {
    let apiKey = Bundle.main.infoDictionary?["Supabase api"] as? String ?? ""
    let urlString = Bundle.main.infoDictionary?["Supabase URL"] as? String ?? ""

    if apiKey.isEmpty || urlString.isEmpty {
      fatalError("⚠️ SUPABASE_API_KEY, SUPABASE_URL Config 설정 빠짐!!")
    }
    if let url = URL(string: "https://" + urlString) {
      return SupabaseClient(supabaseURL: url, supabaseKey: apiKey)
    } else {
      fatalError("⚠️ URL 구성 오류")
    }
  }()
}

extension DependencyValues {
  var postManager: PostManagerProtocol {
    get { self[PostDependencyKey.self] }
    set { self[PostDependencyKey.self] = newValue }
  }

  var supabase: SupabaseClient {
    get { self[SupabaseDependencyKey.self] }
    set { self[SupabaseDependencyKey.self] = newValue }
  }
}
