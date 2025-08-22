//
//  DependencyKeys.swift
//  Bragit
//
//  Created by seongjun cho on 8/22/25.
//

import Foundation

import Dependencies

enum PostDependencyKey: DependencyKey {
  static let liveValue: PostManagerProtocol = PostManager()
  static let testValue: PostManagerProtocol = StubPostManager()
  static let previewValue: PostManagerProtocol = StubPostManager()
}

extension DependencyValues {
  var postManager: PostManagerProtocol {
    get { self[PostDependencyKey.self] }
    set { self[PostDependencyKey.self] = newValue }
  }
}
