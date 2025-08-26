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
    reactor
      .state
      .bind { [weak homeView] item in
        @LocalStorage(location: .blockUser) var blockUsers: [String]?

        // 탈퇴한 유저 처리
        let posts = item.posts.map { post in
          var filteredPost = post
          if filteredPost.author == nil {
            filteredPost.author = Author(id: UUID().uuidString, nickname: "탈퇴한 유저입니다.", profile: nil)
          }
          return filteredPost
        }

        guard blockUsers != nil else {
          return
        }

        // 차단한 유저 제외
        homeView?.feedView.dataApply(data: posts.filter {
          blockUsers!.firstIndex(of: $0.author?.id.rawValue ?? "") == nil
        })
      }
      .disposed(by: disposeBag)

    homeView.feedView.collectionView.rx.reachedBottom()
      .observe(on: MainScheduler.asyncInstance)
      .map { .loadNextPosts }
      .throttle(.seconds(1), latest: false, scheduler: MainScheduler.instance)
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

  }
}
