//
//  UserProfileViewCotnroller.swift
//  Bragit
//
//  Created by 이태윤 on 9/8/25.
//
import UIKit

import RxCocoa
import RxSwift
import ReactorKit

class UserProfileViewCotnroller: UIViewController, View {
  var disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationController?.navigationBar.isHidden = true
    view.backgroundColor = .red
  }

  init(reactor: UserProfileReactor) {
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func bind(reactor: UserProfileReactor) {
  }
}
