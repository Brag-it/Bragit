//
//  SignButton.swift
//  Bragit
//
//  Created by luca on 9/20/25.
//

import SnapKit
import Then
import UIKit

final class SignButton: UIButton {
  private let iconView = UIImageView()
  private let socialLabel = UILabel()

  init(
    title: String,
    icon: UIImage? = nil,
    backgroundColor: UIColor,
    foregroundColor: UIColor
  ) {
    super.init(frame: .zero)
    setupButton(
      title: title,
      icon: icon,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor
    )
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupButton(
    title: String,
    icon: UIImage?,
    backgroundColor: UIColor,
    foregroundColor: UIColor
  ) {
    self.backgroundColor = backgroundColor
    self.layer.cornerRadius = 12
    self.layer.masksToBounds = true
    self.snp.makeConstraints {
      $0.height.equalTo(48)
    }

    if let icon = icon {
      iconView.image = icon.withRenderingMode(.alwaysTemplate)
      iconView.tintColor = foregroundColor
      addSubview(iconView)
      iconView.snp.makeConstraints {
        $0.leading.equalToSuperview().offset(12)
        $0.centerY.equalToSuperview()
        $0.width.height.equalTo(20)
      }
      addSubview(socialLabel)
      socialLabel.snp.makeConstraints {
        $0.leading.equalTo(iconView.snp.trailing).offset(4)
        $0.trailing.equalToSuperview().inset(20)
        $0.centerY.equalToSuperview()
      }
    } else {
      addSubview(socialLabel)
      socialLabel.snp.makeConstraints {
        $0.centerY.equalToSuperview()
        $0.leading.trailing.equalToSuperview().inset(20)
      }
    }

    socialLabel.text = title
    socialLabel.textColor = foregroundColor
    socialLabel.font = .pretendard(size: 14, weight: .medium)
    socialLabel.textAlignment = .center
  }
}
