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

  private let disposeBag = DisposeBag()

  private let alert = AlertView.makeAlert(style: .tempSaveDraft)

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    setupNavigationBar(
        title: "글쓰기",
        leftImage: UIImage(named: "backIcon"),
        rightTitle: "완료"
      )

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


// MARK: - NavigationBar
extension UIViewController {
  func setupNavigationBar(
    title: String,
    leftImage: UIImage? = nil,
    rightTitle: String? = nil
  ) {
    // 타이틀
    navigationController?.navigationBar.titleTextAttributes = [
      .font: UIFont.pretendard(size: 18, weight: .bold),
      .foregroundColor: UIColor.label
    ]
    navigationItem.title = title

    // 왼쪽 버튼
    if let leftImage = leftImage {
      let leftButton = UIBarButtonItem(image: leftImage, style: .plain, target: nil, action: nil)
      navigationItem.leftBarButtonItem = leftButton
    }

    // 오른쪽 버튼
    if let rightTitle = rightTitle {
      let rightButton = UIBarButtonItem(title: rightTitle, style: .done, target: nil, action: nil)
      rightButton.setTitleTextAttributes([
        .font: UIFont.pretendard(size: 16, weight: .bold),
        .foregroundColor: UIColor.systemBlue
      ], for: .normal)
      rightButton.setTitleTextAttributes([
        .font: UIFont.pretendard(size: 16, weight: .bold),
        .foregroundColor: UIColor.systemGray
      ], for: .disabled)
      navigationItem.rightBarButtonItem = rightButton
    }
  }
}
