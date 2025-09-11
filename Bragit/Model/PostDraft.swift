//
//  PostDraft.swift
//  Bragit
//
//  Created by 이태윤 on 8/27/25.
//
import UIKit

struct PostDraft {
  let title: String                   // 제목
  let content: NSAttributedString     // 내용
}

struct PostUpdate {
  let id: UUID
  let title: String
  let content: NSAttributedString
}

// 임시저장
struct PostTemporary: Codable {
  let title: String
  let contentData: Data

  var content: NSAttributedString {
    (try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: contentData)) ?? NSAttributedString()
  }

  init(title: String, content: NSAttributedString) {
    self.title = title
    self.contentData = (try? NSKeyedArchiver.archivedData(withRootObject: content, requiringSecureCoding: false)) ?? Data()
  }

  enum CodingKeys: String, CodingKey {
    case title, contentData
  }
}
