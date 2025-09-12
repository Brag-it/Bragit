//
//  TagDetailViewController.swift
//  Bragit
//
//  Created by seongjun cho on 9/4/25.
//

import UIKit

import RxCocoa
import RxSwift
import ReactorKit

class TagDetailViewController: UIViewController, View {

  var disposeBag = DisposeBag()
  let tagDetailView = TagDetailView()

  override func loadView() {
    view = tagDetailView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationController?.navigationBar.isHidden = true
  }

  init(reactor: TagDetailReactor) {
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func bind(reactor: TagDetailReactor) {
    reactor.state.bind { [tagDetailView] in
      tagDetailView
        .dataApply(tag: $0.tagName, isFollow: $0.isFollow, postCount: $0.postCount, posts: $0.posts)
    }.disposed(by: disposeBag)

    self.rx.viewDidLoad
      .map { .setTagInform }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    tagDetailView.backButton.rx.tap
      .map { .backButtonTap }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    tagDetailView.tagFollowDidTap
      .map { .tagFollowDidTap }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    tagDetailView.followDidTap
      .map { .followDidTap($0) }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    reactor.state.map { $0.postsToReconfigure }
      .distinctUntilChanged()
      .compactMap { $0 }
      .bind { [tagDetailView] posts in
        tagDetailView.reconfigurePosts(posts)
      }
      .disposed(by: disposeBag)

    tagDetailView.collectionView.rx.itemSelected
      .compactMap { [weak self] indexPath -> Post? in
        guard let self, let item = tagDetailView.dataSource.itemIdentifier(for: indexPath)
        else { return nil }
        switch item {
        case .post(let post):
          return post
        default:
          return nil
        }
      }
      .map { post in .didTapPost(post) }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)
  }
}
