//
//  FavoriteViewController.swift
//  Bragit
//
//  Created by 이태윤 on 8/21/25.
//
import UIKit

import RxCocoa
import RxSwift
import ReactorKit

class FavoriteViewController: UIViewController, View {

  var disposeBag = DisposeBag()
  let favoriteView = FavoriteView()

  override func loadView() {
    view = favoriteView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationController?.navigationBar.isHidden = true
  }

  init(reactor: FavoriteReactor) {
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func bind(reactor: FavoriteReactor) {
    // 메뉴 버튼 바인딩
    favoriteView.choiceButton.rx.tap
      .map {
        MenuView(
          items: ["태그", "사용자"],
          width: 120
        )
      }
      .do { [weak self] in
        guard let self = self else { return }
        let button = self.favoriteView.choiceButton
        let point = button.convert(button.bounds, to: self.view)
        $0.show(in: self.view, sourcePoint: CGPoint(x: point.minX, y: point.maxY + 5))
      }
      .flatMap {
        $0.itemTap.take(1).compactMap { $0 }
      }
      .map { index -> FavoriteReactor.Action in
        return .menuTapped(index)
      }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    reactor.state
      .bind { [weak self] state in
        guard let self = self else { return }
        @LocalStorage(location: .blockUser) var blockUsers: [String]?

        switch state.postType {
        case .tag, .emptyTag:
          self.favoriteView.choiceButton.setTitle("태그", for: .normal)
        case .user, .emptyUser:
          self.favoriteView.choiceButton.setTitle("사용자", for: .normal)
        }

        if blockUsers == nil {
          blockUsers = []
        }

        // 탈퇴한 유저, 차단한 유저 처리
        let posts = state.posts.map { post in
          var filteredPost = post
          if filteredPost.author == nil {
            filteredPost.author = Author(id: "", nickname: "탈퇴한 유저입니다.", profile: nil)
          }
          return filteredPost
        }.filter {
          blockUsers!.firstIndex(of: $0.author?.id.rawValue ?? "") == nil
        }

        self.favoriteView.feedView.dataApply(
          posts: posts,
          postType: state.postType,
          selectedTag: state.selectedTag
        )
      }
      .disposed(by: disposeBag)
    // 게시글 하단까지 내릴 시 다음 게시글 요청
    favoriteView.feedView.collectionView.rx.reachedBottom()
      .observe(on: MainScheduler.asyncInstance)
      .map { .loadNextPosts }
      .throttle(.seconds(1), latest: false, scheduler: MainScheduler.instance)
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    // 초기 설정
    self.rx.viewDidLoad
      .map { .menuTapped(0) }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    // 태그 탭
    favoriteView.feedView.tagDidTap
      .map { tag in .tagTapped(tag) }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    // 팔로우 버튼 탭
    favoriteView.feedView.followDidTap
      .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
      .map { post in .followButtonTapped(post) }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    // 특정 포스트들 갱신
    reactor.state.map { $0.postsToReconfigure }
      .distinctUntilChanged()
      .compactMap { $0 }
      .bind { [weak self] posts in
        self?.favoriteView.feedView.reconfigurePosts(posts)
      }
      .disposed(by: disposeBag)
  }
}
