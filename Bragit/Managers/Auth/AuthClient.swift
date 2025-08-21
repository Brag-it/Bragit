//
//  AuthClient.swift
//  Bragit
//
//  Created by luca on 8/21/25.
//

import Supabase
import Foundation

enum AuthClient {
  static let shared: SupabaseClient = {
    let (url, key) = Self.loadKeys()
    return SupabaseClient(supabaseURL: url, supabaseKey: key)
  }()
  
  private static func loadKeys() -> (URL, String) {
    guard
      let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
      let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
      let urlStr = dict["SUPABASE_URL"] as? String,
      let key = dict["SUPABASE_KEY"] as? String,
      let url = URL(string: urlStr)
    else {
      fatalError("SupabaseKeys are missing or invalid")
    }
    return (url, key)
  }
}
