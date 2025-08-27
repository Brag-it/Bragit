//
//  MyPageViewController.swift
//  Bragit
//
//  Created by 이태윤 on 8/21/25.
//
import UIKit

import ReactorKit
import RxSwift
import RxCocoa

class MyPageViewController: UIViewController, View {
  var disposeBag = DisposeBag()

  init(reactor: MyPageReactor) {
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .green
  }

  func bind(reactor: MyPageReactor) {
  }
}
