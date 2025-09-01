//
//  FavoriteView.swift
//  Bragit
//
//  Created by seongjun cho on 8/26/25.
//

import UIKit

import Then
import SnapKit

class FavoriteView: UIView {
  private let headerView = UIView().then {
    $0.backgroundColor = .white
  }

  private let searchButton = UIButton().then {
    $0.setImage(.search, for: .normal)
  }

  let choiceButton = UIButton().then {
    $0.setImage(.drop, for: .normal)
    $0.setTitle("태그", for: .normal)
    $0.setTitleColor(UIColor(red: 0.34, green: 0.34, blue: 0.34, alpha: 1), for: .normal)
    $0.titleLabel?.font = .pretendard(size: 18, weight: .semibold)
    $0.semanticContentAttribute = .forceRightToLeft
  }

  let feedView = FavoriteFeedView()

  override init(frame: CGRect) {
    super.init(frame: frame)

    setUI()
    self.backgroundColor = .white
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setUI() {
    addSubview(headerView)
    addSubview(feedView)
    headerView.addSubview(searchButton)
    headerView.addSubview(choiceButton)

    headerView.snp.makeConstraints {
      $0.top.leading.trailing.equalTo(safeAreaLayoutGuide)
      $0.height.equalTo(58)
    }

    searchButton.snp.makeConstraints {
      $0.centerY.equalToSuperview()
      $0.width.height.equalTo(24)
      $0.trailing.equalToSuperview().inset(20)
    }

    choiceButton.snp.makeConstraints {
      $0.centerY.equalToSuperview()
      $0.leading.equalToSuperview().offset(20)
    }

    feedView.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom)
      $0.leading.trailing.bottom.equalToSuperview()
    }
  }
}
