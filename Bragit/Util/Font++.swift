//
//  Font++.swift
//  Bragit
//
//  Created by 이태윤 on 8/21/25.
//

import UIKit

extension UIFont {
  static func pretendard(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
    let descriptor = UIFontDescriptor(
      fontAttributes: [
        .family: "Pretendard",
        .traits: [
          UIFontDescriptor.TraitKey.weight: weight
        ]
      ]
    )

    return UIFont(descriptor: descriptor, size: size)
  }
}
