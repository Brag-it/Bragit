//
//  MarkDownAccessoryView.swift
//  Bragit
//
//  Created by 이태윤 on 8/27/25.
//
import UIKit

import SnapKit
import Then
import RxSwift
import RxCocoa

final class MarkdownAccessoryView: UIView {
  let boldButton = UIButton(type: .system).then {
    $0.setTitle("B", for: .normal)
    $0.titleLabel?.font = .boldSystemFont(ofSize: 16)
  }

  let italicButton = UIButton(type: .system).then {
    $0.setTitle("i", for: .normal)
    $0.titleLabel?.font = .italicSystemFont(ofSize: 16)
  }

  let headerButton = UIButton(type: .system).then {
    $0.setTitle("#", for: .normal)
    $0.titleLabel?.font = .pretendard(size: 16)
  }

  let bulletButton = UIButton(type: .system).then {
    $0.setTitle("•", for: .normal)
    $0.titleLabel?.font = .pretendard(size: 16)
  }

  private lazy var stackView = UIStackView(arrangedSubviews: [
    boldButton, italicButton, headerButton, bulletButton
  ]).then {
    $0.axis = .horizontal
    $0.spacing = 12
    $0.distribution = .fillEqually
    $0.alignment = .center
  }

  override init(frame: CGRect) {
    super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
    backgroundColor = .secondarySystemBackground
    setupLayout()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupLayout() {
    addSubview(stackView)

    stackView.snp.makeConstraints {
      $0.directionalEdges.equalToSuperview().inset(12)
      $0.height.equalTo(40)
    }
  }
}
