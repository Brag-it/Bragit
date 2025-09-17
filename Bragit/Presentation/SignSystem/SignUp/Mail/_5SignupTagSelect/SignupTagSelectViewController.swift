//
//  SignupTagSelectViewController.swift
//  Bragit
//
//  Created by luca on 9/17/25.
//

import ReactorKit
import RxCocoa
import RxSwift
import UIKit

// 이메일 가입 5단계
// 가입자에게 관심있는 태그를 선택할 수 있는 선택지를 줌

final class SignupTagSelectViewController: UIViewController {
  private let disposeBag = DisposeBag()
  private let rootView = SignupTagSelectView()

  override func loadView() {
    self.view = rootView
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(true, animated: false)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    bind()
  }

  private func bind() {

  }
}
