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
    view.backgroundColor = .blue
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
      .flatMap { index -> Observable<FavoriteReactor.Action> in
        switch index {
        case 0:
          return .from([.setPostType(.tag), .loadTagsPosts])
        case 1:
          return .from([.setPostType(.user), .loadUsersPosts])
        default:
          return .from([.setPostType(.tag), .loadTagsPosts])
        }
      }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)
  }
}
