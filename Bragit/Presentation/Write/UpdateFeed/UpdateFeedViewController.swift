//
//  UpdateFeedViewController.swift
//  Bragit
//
//  Created by 이태윤 on 9/9/25.
//
import UIKit

import RxCocoa
import RxSwift
import ReactorKit

class UpdateFeedViewController: UIViewController, View {
  var disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationController?.navigationBar.isHidden = true
    view.backgroundColor = .blue
    print("게시물 ID: \(String(describing: reactor?.currentState.postId))")
    print("제목: \(String(describing: reactor?.currentState.title))")
    print("본문: \(String(describing: reactor?.currentState.content))")
  }

  init(reactor: UpdateFeedReactor) {
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func bind(reactor: UpdateFeedReactor) {
  }
}
