//
//  KeychainMailStore.swift
//  Bragit
//
//  Created by luca on 8/25/25.
//

enum KeychainMailStore {
  private static let key = "pendingMail"

  static func save(_ mail: String) {
    KeychainHelper.set(mail, forKey: key)
  }

  static func load() -> String? {
    KeychainHelper.get(forKey: key)
  }

  static func clear() {
    KeychainHelper.remove(forKey: key)
  }
}
