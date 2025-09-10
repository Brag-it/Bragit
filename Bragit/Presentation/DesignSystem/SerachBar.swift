//
//  SerachBar.swift
//  Bragit
//
//  Created by 이태윤 on 9/2/25.
//
import UIKit

import SnapKit
import Then
import RxSwift
import RxCocoa

final class SearchBar: UIView {
  var disposeBag = DisposeBag()

  let stackView = UIStackView().then {
    $0.backgroundColor = .white
    $0.axis = .horizontal
    $0.spacing = 10
    $0.alignment = .center
    $0.isLayoutMarginsRelativeArrangement = true
    $0.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
  }

  let textField = UITextField().then {
    $0.font = .pretendard(size: 15)
    $0.textColor = .grayScale900
    $0.returnKeyType = .search
    $0.clearButtonMode = .never
    $0.autocorrectionType = .no
    $0.autocapitalizationType = .none
    $0.setContentHuggingPriority(.defaultLow, for: .horizontal)
    $0.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
  }

  let searchButton = UIButton(type: .system).then {
    $0.setImage(.search, for: .normal)
    $0.tintColor = .grayScaleBack
    $0.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    $0.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    self.layer.cornerRadius = 12
    self.layer.borderWidth = 1
    self.layer.borderColor = UIColor.grayScale100.cgColor
    self.addSubview(stackView)
    stackView.addArrangedSubview(textField)
    stackView.addArrangedSubview(searchButton)

    stackView.snp.makeConstraints {
      $0.directionalEdges.equalToSuperview()
      $0.height.equalTo(48)
    }

    textField.snp.makeConstraints {
      $0.height.equalTo(21)
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
