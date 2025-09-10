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

enum TagDependencyKey: DependencyKey {
  static let liveValue: TagManagerProtocol = TagManager()
}

enum UserDependencyKey: DependencyKey {
  static let liveValue: UserManagerProtocol = UserManager()
}

enum SearchDependencyKey: DependencyKey {
  static let liveValue: SearchManagerProtocol = SearchManager()
}

enum ReportDependencyKey: DependencyKey {
  static let liveValue: ReportManagerProtocol = ReportManager()
}

enum BlockDependencyKey: DependencyKey {
  static let liveValue: BlockManagerProtocol = BlockManager()
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

  var authClient: AuthClient {
    get { self[AuthClient.self] }
    set { self[AuthClient.self] = newValue }
  }

  var tagManager: TagManagerProtocol {
    get { self[TagDependencyKey.self] }
    set { self[TagDependencyKey.self] = newValue }
  }

  var userManager: UserManagerProtocol {
    get { self[UserDependencyKey.self] }
    set { self[UserDependencyKey.self] = newValue }
  }

  var searchManager: SearchManagerProtocol {
    get { self[SearchDependencyKey.self] }
    set { self[SearchDependencyKey.self] = newValue }
  }

  var blockManager: BlockManagerProtocol {
    get { self[BlockDependencyKey.self] }
    set { self[BlockDependencyKey.self] = newValue }
  }

  var reportManager: ReportManagerProtocol {
    get { self[ReportDependencyKey.self] }
    set { self[ReportDependencyKey.self] = newValue }
  }
}
