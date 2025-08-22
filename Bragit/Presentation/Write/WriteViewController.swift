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

  private let doneButton = UIBarButtonItem(title: "완료", style: .done, target: nil, action: nil).then {
    $0.isEnabled = false
    $0.setTitleTextAttributes([
      .font: UIFont.pretendard(size: 14, weight: .regular)
    ], for: .normal)
    $0.setTitleTextAttributes([
      .font: UIFont.pretendard(size: 14, weight: .regular)
    ], for: .disabled)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    navigationItem.title = "글쓰기"
    navigationItem.rightBarButtonItem = doneButton
    bind()
  }

  private func bind() {
    alert.leftTap
      .bind { print("왼쪽 버튼 누름") }
      .disposed(by: disposeBag)

    alert.rightTap
      .bind { print("오른쪽 버튼 누름") }
      .disposed(by: disposeBag)

//    alert.show(in: self.view)
  }
}
