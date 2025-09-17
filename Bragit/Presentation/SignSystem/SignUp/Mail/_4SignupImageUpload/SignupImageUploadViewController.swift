//
//  SignupImageUploadViewController.swift
//  Bragit
//
//  Created by luca on 9/17/25.
//

import ReactorKit
import RxCocoa
import RxSwift
import UIKit

// 이메일 가입 4단계
// 가입자에게 프로필 사진 등록에 대한 선택권을 줌

final class SignupImageUploadViewController: UIViewController {
  private let disposeBag = DisposeBag()
  private let rootView = SignupMailInfoView()

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
