//
//  AuthClient.swift
//  Bragit
//
//  Created by luca on 8/21/25.
//

import Foundation

import Dependencies
import Supabase

struct AuthClient {
  var signInWithApple: (_ idToken: String, _ nonce: String) async throws -> Void
}

extension AuthClient {
  static func live() -> Self {
    .init { idToken, nonce in
      @Dependency(\.supabase) var supabase
      _ = try await supabase.auth
        .signInWithIdToken(
          credentials: OpenIDConnectCredentials(
            provider: .apple,
            idToken: idToken,
            nonce: nonce
          )
        )
    }
  }
}

extension AuthClient: DependencyKey {
  static let liveValue: AuthClient = .live()
}

