//
//  FollowerVIewController.swift
//  Bragit
//
//  Created by seongjun cho on 9/3/25.
//

import UIKit

import ReactorKit

class FollowerViewController: ProfileListViewController<User>, View {

  let users: [User]

  init(reactor: FollowerReactor, users: [User]) {
    self.users = users
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    titleText = "팔로워"
    subTitleText = String(users.count)
    dataApply(data: users)
  }

  func bind(reactor: FollowerReactor) {
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
