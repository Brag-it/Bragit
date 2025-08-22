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

final class WriteViewController: UIViewController {

  let disposeBag = DisposeBag()

  let alert = AlertView.makeAlert(style: .tempSaveDraft)

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    bind()
  }

  private func bind() {
    alert.leftTap
      .bind { print("왼쪽 버튼 누름") }
      .disposed(by: disposeBag)

    alert.rightTap
      .bind { print("오른쪽 버튼 누름") }
      .disposed(by: disposeBag)

    alert.show(in: self.view)
  }
}
