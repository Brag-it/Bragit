//
//  BlockUserViewController.swift
//  Bragit
//
//  Created by seongjun cho on 9/18/25.
//

import UIKit

import RxSwift
import RxCocoa
import ReactorKit
import RxRelay

class BlockUserViewController: UIViewController, View {

  let blockUserView = BlockUserView()

  var disposeBag = DisposeBag()

  init(reactor: BlockUserReactor) {
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    view = blockUserView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationController?.navigationBar.isHidden = true

  }

  func reload() {
    blockUserView.collectionView.reloadData()
  }

  func bind(reactor: BlockUserReactor) {
    blockUserView.backButton.rx.tap
      .map { .backButtonTap }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    blockUserView.blockDidTap
      .map { .blockButtonTap($0) }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    blockUserView.collectionView.rx.itemSelected
      .compactMap { [blockUserView] indexPath in
        return blockUserView.dataSource.itemIdentifier(for: indexPath)
      }
      .map {
        switch $0 {
        case .user(let user):
          .userDidTap(user)
        case .empty:
          .dataLoad
        }
      }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    reactor.state.bind { [blockUserView] in
      blockUserView.dataApply(data: $0.users)
      blockUserView.subTitleLabel.text = String($0.users.count)
    }.disposed(by: disposeBag)

    self.rx.viewWillAppear
      .bind { _ in self.reload() }
      .disposed(by: disposeBag)

    self.rx.viewDidLoad
      .map { .dataLoad }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)
  }
}
