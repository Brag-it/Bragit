//
//  HomeView.swift
//  Bragit
//
//  Created by seongjun cho on 8/22/25.
//

import UIKit

import SnapKit
import Then

final class HomeView: UIView {

  private let headerView = UIView().then {
    $0.backgroundColor = .white
  }

  private let searchButton = UIButton().then {
    $0.setImage(.search, for: .normal)
  }

  private let logoImageView = UIImageView().then {
    $0.contentMode = .scaleAspectFit
    $0.image = .headerLogo
  }

  let feedView = FeedView()

  override init(frame: CGRect) {
    super.init(frame: frame)

    setupUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupUI() {
    addSubview(headerView)
    headerView.addSubview(logoImageView)
    headerView.addSubview(searchButton)
    addSubview(feedView)

    headerView.snp.makeConstraints {
      $0.top.leading.trailing.equalTo(safeAreaLayoutGuide)
      $0.height.equalTo(58)
    }

    logoImageView.snp.makeConstraints {
      $0.centerX.centerY.equalToSuperview()
    }

    searchButton.snp.makeConstraints {
      $0.centerY.equalToSuperview()
      $0.width.height.equalTo(24)
      $0.trailing.equalToSuperview().inset(20)
    }

    feedView.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom)
      $0.leading.trailing.bottom.equalTo(safeAreaLayoutGuide)
    }
  }
}
