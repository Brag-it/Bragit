//
//  FavoriteTagsViewController.swift
//  Bragit
//
//  Created by seongjun cho on 9/4/25.
//

import UIKit

import ReactorKit

class FavoriteTagsViewController: ProfileListViewController<Tag>, View {

  let tags: [Tag]

  init(reactor: FavoriteTagsReactor, tags: [Tag]) {
    self.tags = tags
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    titleText = "관심 태그"
    subTitleText = String(tags.count)
    dataApply(data: tags)
  }

  func bind(reactor: FavoriteTagsReactor) {
    profileListView.backButton.rx.tap
      .map { .backButtonTap }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    self.followDidTap
      .map { return .followButtonTap($0) }
      .compactMap { $0 }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)
  }
}
