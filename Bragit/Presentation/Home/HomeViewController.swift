//
//  HomeViewController.swift
//  Bragit
//
//  Created by 이태윤 on 8/21/25.
//

import UIKit

import RxCocoa
import ReactorKit

class HomeViewController: UIViewController, View {
  var disposeBag = DisposeBag()
  private let homeView = HomeView()

  override func loadView() {
    view = homeView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationController?.navigationBar.isHidden = true
    reactor?.action.onNext(.loadPosts)
  }

  init(reactor: HomeReactor) {
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func bind(reactor: HomeReactor) {
    // 게시글 바인딩
    reactor.state.map { $0.posts }
      .distinctUntilChanged()
      .bind { [weak homeView] posts in
        @LocalStorage(location: .blockUser) var blockUsers: [String]?

        if blockUsers == nil {
          blockUsers = []
        }

        // 탈퇴한 유저, 차단한 유저 처리
        let posts = posts.map { post in
          var filteredPost = post
          if filteredPost.author == nil {
            filteredPost.author = Author(id: "", nickname: "탈퇴한 유저입니다.", profile: nil)
          }
          return filteredPost
        }.filter {
          blockUsers!.firstIndex(of: $0.author?.id.rawValue ?? "") == nil
        }

        homeView?.feedView.dataApply(data: posts)
      }
      .disposed(by: disposeBag)

    // 게시글 하단까지 내릴 시 다음 게시글 요청
    homeView.feedView.collectionView.rx.reachedBottom()
      .observe(on: MainScheduler.asyncInstance)
      .map { .loadNextPosts }
      .throttle(.seconds(1), latest: false, scheduler: MainScheduler.instance)
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    // 팔로우 버튼 탭
    homeView.feedView.followDidTap
      .map { .followButtonTapped($0) }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    // TODO: 태그 탭 이벤트
    //homeView.feedView.tagDidTap

    // 특정 포스트들 갱신
    reactor.state.map { $0.postsToReconfigure }
      .distinctUntilChanged()
      .compactMap { $0 }
      .bind { [weak self] posts in
        self?.homeView.feedView.reconfigurePosts(posts)
      }
      .disposed(by: disposeBag)

    homeView.feedView.collectionView.rx.itemSelected
      .compactMap { [weak self] indexPath -> Post? in
        return self?.homeView.feedView.dataSource.itemIdentifier(for: indexPath)
      }
      .map { post in
        Reactor.Action.didTapPost(post)
      }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)
  }
}
