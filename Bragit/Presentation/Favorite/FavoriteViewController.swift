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

class FavoriteViewController: UIViewController {
  private let reactor: FavoriteReactor
  private let disposeBag = DisposeBag()

  init(reactor: FavoriteReactor) {
    self.reactor = reactor
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .fullScreen
    modalTransitionStyle = .crossDissolve
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .blue
  }
}
