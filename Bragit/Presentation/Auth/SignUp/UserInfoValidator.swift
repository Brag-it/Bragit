//
//  UserInfoValidator.swift
//  Bragit
//
//  Created by luca on 8/27/25.
//

import Foundation

enum UserInfoValidator {
  static func isValidMail(_ text: String) -> Bool {
    let pattern = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
    return match(text, pattern, options: [.caseInsensitive])
  }

  static func isValidPassword(_ pwd: String) -> Bool {
    guard (8...24).contains(pwd.count) else { return false }
    return !pwd.contains(" ")
  }

  static func isValidNickname(_ name: String) -> Bool {
    let pattern = "^[가-힣A-Za-z0-9]{2,8}$"
    return match(name, pattern)
  }

  private static func match(_ text: String, _ pattern: String, options: NSRegularExpression.Options = []) -> Bool {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return false }
    let range = NSRange(location: 0, length: (text as NSString).length)
    return regex.firstMatch(in: text, options: [], range: range) != nil
  }
}
