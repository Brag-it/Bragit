//
//  PreviewViewController.swift
//  Bragit
//
//  Created by 이태윤 on 8/27/25.
//
import UIKit

import ReactorKit
import RxSwift
import RxCocoa
import SnapKit
import Then

class PreviewViewController: UIViewController, View {
  var disposeBag = DisposeBag()

  private let headerView = UIView()

  private let backButton = UIButton(type: .system).then {
    $0.setImage(.back, for: .normal)
    $0.tintColor = .grayScale900
  }

  private let titleLabel = UILabel().then {
    $0.text = "글쓰기"
    $0.font = .pretendard(size: 16)
    $0.textColor = .grayScale900
    $0.textAlignment = .center
    $0.setContentHuggingPriority(.defaultLow, for: .horizontal)
  }

  private let titleTextField = UITextField().then {
    $0.placeholder = "제목을 입력해 주세요"
    $0.borderStyle = .none
    $0.font = .pretendard(size: 20, weight: .semibold)
  }

  private let dividerView = UIView().then {
    $0.backgroundColor = .lightGray
  }

  init(reactor: PreviewReactor) {
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    self.navigationController?.isNavigationBarHidden = true
    setUIConstraints()
    print("넘어온 데이터 : \(String(describing: self.reactor?.draft))")
  }

  // UI 설정
  private func setUIConstraints() {

    view.addSubview(headerView)

    headerView.addSubview(backButton)
    headerView.addSubview(titleLabel)

    view.addSubview(titleTextField)
    view.addSubview(dividerView)

    headerView.snp.makeConstraints {
      $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
      $0.leading.trailing.equalToSuperview()
      $0.height.equalTo(58)
    }
    backButton.snp.makeConstraints {
      $0.leading.equalToSuperview().offset(20)
      $0.centerY.equalTo(headerView.snp.centerY)
    }

    titleLabel.snp.makeConstraints {
      $0.centerX.equalTo(headerView.snp.centerX)
      $0.centerY.equalTo(headerView.snp.centerY)
      $0.leading.greaterThanOrEqualTo(backButton.snp.trailing).offset(20)
    }

    titleTextField.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom).offset(24)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    dividerView.snp.makeConstraints {
      $0.top.equalTo(titleTextField.snp.bottom).offset(16)
      $0.leading.trailing.equalTo(titleTextField)
      $0.height.equalTo(1)
    }
  }

  func bind(reactor: PreviewReactor) {
    // 제목
    reactor.state
      .map(\.title)
      .bind(to: titleTextField.rx.text)
      .disposed(by: disposeBag)

//    // 썸네일 (이미지가 있을 경우만)
//    reactor.state
//      .map { $0.thumbnail }
//      .bind(to: thumbnailImageView.rx.image)
//      .disposed(by: disposeBag)
//
//    // 미리보기 텍스트
//    reactor.state
//      .map(\.decription)
//      .bind(to: descriptionLabel.rx.text)
//      .disposed(by: disposeBag)
  }
}

@available(iOS 17.0, *)
#Preview {
  let sampleDraft = PostDraft(
    title: "샘플 제목",
    content: NSAttributedString(string: "샘플 내용")
  )
  let reactor = PreviewReactor(draft: sampleDraft)
  return UINavigationController(rootViewController: PreviewViewController(reactor: reactor))
}
