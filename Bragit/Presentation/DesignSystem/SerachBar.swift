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

  let container = UIView().then {
    $0.backgroundColor = .white
    $0.layer.cornerRadius = 12
    $0.layer.borderWidth = 1
    $0.layer.borderColor = UIColor.grayScale100.cgColor
  }

  let textField = UITextField().then {
    $0.font = .pretendard(size: 15)
    $0.textColor = .grayScale900
    $0.returnKeyType = .search
    $0.clearButtonMode = .never
    $0.autocorrectionType = .no
    $0.autocapitalizationType = .none
  }

  let searchButton = UIButton(type: .system).then {
    $0.setImage(.search, for: .normal)
    $0.tintColor = .grayScaleBack
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(container)
    container.addSubview(textField)
    container.addSubview(searchButton)

    container.snp.makeConstraints {
      $0.directionalEdges.equalToSuperview()
      $0.height.equalTo(48)
    }

    textField.snp.makeConstraints {
      $0.top.bottom.equalToSuperview().inset(8)
      $0.leading.equalToSuperview().inset(12)
      $0.trailing.equalTo(searchButton.snp.leading).offset(-10)
    }

    searchButton.snp.makeConstraints {
      $0.trailing.equalToSuperview().inset(12)
      $0.centerY.equalToSuperview()
      $0.height.equalTo(textField)
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
