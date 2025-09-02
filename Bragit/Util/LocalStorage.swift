//
//  LocalStorage.swift
//  Bragit
//
//  Created by seongjun cho on 8/25/25.
//

import Foundation

@propertyWrapper
struct LocalStorage<V: Codable> {
  let location: LocalStorageCase

  var wrappedValue: V {
    didSet {
      save(wrappedValue)
    }
  }

  private var userDefaults: UserDefaults {
//    let suiteName = UserDefaults.standard.string(forKey: LocalStorageCase.nowUser.rawValue)
    let suiteName = UserDefaults.standard.string(forKey: "nowUser")
    return UserDefaults(suiteName: suiteName) ?? .standard
  }

  init(wrappedValue: V, location: LocalStorageCase) {
    self.location = location
    if let savedValue = Self.load(from: location) {
      self.wrappedValue = savedValue
    } else {
      self.wrappedValue = wrappedValue
      save(wrappedValue)
    }
  }

  init<T>(location: LocalStorageCase) where V == T? {
    self.location = location
    self.wrappedValue = Self.load(from: location) ?? nil
  }

  private func save(_ value: V) {
    if let data = try? JSONEncoder().encode(value) {
      userDefaults.set(data, forKey: location.rawValue)
    } else {
      print("⚠️ LocalStorage Endcoding Error (value: \(value))")
    }
  }

  private static func load(from location: LocalStorageCase) -> V? {
    let suiteName = UserDefaults.standard.string(forKey: "nowUser")
    let userDefaults = UserDefaults(suiteName: suiteName) ?? .standard

    if location == .nowUser {
      return suiteName as? V
    }

    guard let data = userDefaults.data(forKey: location.rawValue) else {
      print("⚠️ LocalStorage의 \(location.rawValue)에 저장된 데이터가 없습니다.")
      return nil
    }

    if let result = try? JSONDecoder().decode(V.self, from: data) {
      return result
    } else {
      print("⚠️ LocalStorage Decoding Error (location: \(location))")
      return nil
    }
  }
}
