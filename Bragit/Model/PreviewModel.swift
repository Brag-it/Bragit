//
//  PreviewModel.swift
//  Bragit
//
//  Created by 이태윤 on 9/1/25.
//
import UIKit

enum Section: CaseIterable {
  case title
  case thumbnails
  case description
  case tags
}

enum Item: Hashable {
  case title(TitleItem)
  case thumbnail(ThumbnailItem)
  case description(DescriptionItem)
  case tag(TagItem)

  var id: UUID {
    switch self {
    case .title(let titleItem): return titleItem.id
    case .thumbnail(let thumbnailItem): return thumbnailItem.id
    case .description(let descriptionItem): return descriptionItem.id
    case .tag(let tagItem): return tagItem.id
    }
  }

  func hash(into hasher: inout Hasher) { hasher.combine(id) }
  static func == (lhs: Item, rhs: Item) -> Bool { lhs.id == rhs.id }
}

// MARK: - Models

struct TitleItem: Hashable {
  let id = UUID()
  var text: String = ""
}

struct ThumbnailItem: Hashable {
  enum Kind {
    case addButton
    case image(UIImage)
  }

  let id = UUID()
  let kind: Kind
  var isSelected: Bool = false

  func hash(into hasher: inout Hasher) { hasher.combine(id) }
  static func == (lhs: ThumbnailItem, rhs: ThumbnailItem) -> Bool { lhs.id == rhs.id }
}

struct DescriptionItem: Hashable {
  let id = UUID()
  var text: String
}

struct TagItem: Hashable {
  let id = UUID()
  var tag: String
}

enum PostImageType {
  case thumbnail   // 대표 썸네일
  case content     // 본문 이미지

  // 리사이즈할 최대 픽셀과 JPEG 압축 품질
  var config: (maxDimension: CGFloat, quality: CGFloat) {
    switch self {
    case .thumbnail:
      return (maxDimension: 600, quality: 0.7)
    case .content:
      return (maxDimension: 1280, quality: 0.8)
    }
  }
}
