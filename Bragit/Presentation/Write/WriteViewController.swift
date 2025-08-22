//
//  WriteViewController.swift
//  Bragit
//
//  Created by 이태윤 on 8/20/25.
//
import UIKit

import SnapKit
import Then
import RxSwift
import RxCocoa

class WriteViewController: UIViewController {

  let disposeBag = DisposeBag()

  let alert = CustomAlertView(
    title: "작성 중인 글을 임시저장할까요?",
    message: "저장하지 않은 글은 삭제됩니다.저장하지 않은 글은 삭제됩니다.저장하지 않은 글은 삭제됩니다.",
    leftButtonTitle: "삭제하기",
    rightButtonTitle: "임시저장"
  )

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .red

    alert.leftTap
      .bind { print("삭제하기 눌림") }
      .disposed(by: disposeBag)

    alert.rightTap
      .bind { print("임시저장 눌림") }
      .disposed(by: disposeBag)

    alert.show(in: self.view)

  }
}
