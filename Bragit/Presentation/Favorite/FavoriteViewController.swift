//
//  FavoriteViewController.swift
//  Bragit
//
//  Created by 이태윤 on 8/21/25.
//
import UIKit

import ReactorKit
import RxSwift
import RxCocoa

class FavoriteViewController: UIViewController, View {
  var disposeBag = DisposeBag()

  init(reactor: FavoriteReactor) {
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .blue
  }
  func bind(reactor: FavoriteReactor) {
  }
}
