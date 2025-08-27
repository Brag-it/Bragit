//
//  KeychainHelper.swift
//  Bragit
//
//  Created by luca on 8/25/25.
//

import Foundation
import Security

enum KeychainHelper {
  @discardableResult
  static func set(
    _ value: String,
    forKey key: String,
    service: String = Bundle.main.bundleIdentifier ?? "default.service"
  )
    -> Bool {
    guard let data = value.data(using: .utf8) else { return false }

    SecItemDelete(
      [
        kSecClass: kSecClassGenericPassword,
        kSecAttrService: service,
        kSecAttrAccount: key
      ] as CFDictionary
    )

    let query: [CFString: Any] = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: service,
      kSecAttrAccount: key,
      kSecValueData: data,
      kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
    ]
    return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
  }

  static func get(forKey key: String, service: String = Bundle.main.bundleIdentifier ?? "default.service") -> String? {
    let query: [CFString: Any] = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: service,
      kSecAttrAccount: key,
      kSecReturnData: true,
      kSecMatchLimit: kSecMatchLimitOne
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status == errSecSuccess, let data = item as? Data else { return nil }
    return String(data: data, encoding: .utf8)
  }

  @discardableResult
  static func remove(forKey key: String, service: String = Bundle.main.bundleIdentifier ?? "default.service") -> Bool {
    let query: [CFString: Any] = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: service,
      kSecAttrAccount: key
    ]
    return SecItemDelete(query as CFDictionary) == errSecSuccess
  }
}
