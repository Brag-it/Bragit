//
//  AuthClient.swift
//  Bragit
//
//  Created by luca on 8/21/25.
//

import Foundation
import Supabase

enum Config {
  static var supabaseURL: URL {
    guard
      let raw = Bundle.main.object(forInfoDictionaryKey: "Supabase URL") as? String
    else {
      fatalError("Info.plist: Supabase URL have a problem.")
    }
    let urlString = raw.hasPrefix("http") ? raw : "https://\(raw)"
    guard let url = URL(string: urlString) else {
      fatalError("Supabase URL: \(urlString)")
    }
    return url
  }

  static var supabaseKey: String {
    guard let key = Bundle.main.object(forInfoDictionaryKey: "Supabase api") as? String, !key.isEmpty else {
      fatalError("Info.plist: Supabase api have a problem.")
    }
    return key
  }
}

enum AuthClient {
  static let shared: SupabaseClient = {
    SupabaseClient(
      supabaseURL: Config.supabaseURL,
      supabaseKey: Config.supabaseKey
    )
  }()
}
