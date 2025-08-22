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

  private let disposeBag = DisposeBag()

  private let alert = AlertView.makeAlert(style: .tempSaveDraft)

  private let titleLabel = UILabel().then {
    $0.text = "글쓰기"
    $0.font = .pretendard(size: 18, weight: .medium)
    $0.textColor = .label
    $0.textAlignment = .center
  }

  private let backButton = UIButton(type: .system).then {
    $0.setImage(.xMarker, for: .normal)
    $0.tintColor = .black
  }

  private let doneButton = UIButton(type: .system).then {
    $0.setTitle("완료", for: .normal)
    $0.setTitleColor(.black, for: .normal)
    $0.setTitleColor(.systemGray, for: .disabled)
    $0.titleLabel?.font = .pretendard(size: 14)
    $0.isEnabled = true // 비활성화 예정
  }

  init() {
    super.init(nibName: nil, bundle: nil)
//    modalTransitionStyle = .crossDissolve
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    let backBarButton = UIBarButtonItem(customView: backButton)
    let doneBarButton = UIBarButtonItem(customView: doneButton)
    navigationItem.titleView = titleLabel
    navigationItem.leftBarButtonItem = backBarButton
    navigationItem.rightBarButtonItem = doneBarButton

    bind()
  }

  private func bind() {
    alert.leftTap
      .bind { [weak self] in
        self?.dismiss(animated: true)
      }
      .disposed(by: disposeBag)

    alert.rightTap
      .bind { print("오른쪽 버튼 누름") }
      .disposed(by: disposeBag)

    backButton.rx.tap
      .bind { [weak self] in
        guard let self else { return }
        alert.show(in: view)
      }
      .disposed(by: disposeBag)
  }
}
