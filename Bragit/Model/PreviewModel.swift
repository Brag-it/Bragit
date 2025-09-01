//
//  PreviewModel.swift
//  Bragit
//
//  Created by 이태윤 on 9/1/25.
//
enum Section: CaseIterable {
  case title
  case thumbnails
  case description
  case tags
}

enum Item: Hashable {
  case thumbnail(ThumbnailItem)     // 썸네일
  case description(DescriptionItem) // 설명
  case tag(TagItem)                 // 태그
}

struct ThumbnailItem: Hashable {
  enum ItemType: Hashable {
    case addButton            // 고정 추가 버튼 셀
    case image(UIImage)       // 썸네일 이미지 셀
  }

  let id: UUID = UUID()
  let type: ItemType
  var isSelected: Bool = false
  
  func hash(into hasher: inout Hasher) { hasher.combine(id) }
  static func == (lhs: ThumbnailItem, rhs: ThumbnailItem) -> Bool { lhs.id == rhs.id }
}

struct DescriptionItem: Hashable {
  let id: UUID = UUID()
  var text: String
}

struct TagItem: Hashable {
  let id: UUID = UUID()
  var title: String
  var isDeletable: Bool = true
}
