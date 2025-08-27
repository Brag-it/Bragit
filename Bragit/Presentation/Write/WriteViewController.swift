//
//  WriteViewController.swift
//  Bragit
//
//  Created by 이태윤 on 8/20/25.
//
import UIKit

import ReactorKit
import RxSwift
import RxCocoa
import SnapKit
import Then

class WriteViewController: UIViewController, View {
  var disposeBag = DisposeBag()
  private let alert = AlertView.makeAlert(style: .tempSaveDraft)

  private let headerView = UIView()

  private let backButton = UIButton(type: .system).then {
    $0.setImage(.xMarker, for: .normal)
    $0.tintColor = .black
  }

  private let titleLabel = UILabel().then {
    $0.text = "글쓰기"
    $0.font = .pretendard(size: 18, weight: .medium)
    $0.textColor = .label
    $0.textAlignment = .center
    $0.setContentHuggingPriority(.defaultLow, for: .horizontal)
  }

  private let doneButton = UIButton(type: .system).then {
    $0.setTitle("완료", for: .normal)
    $0.setTitleColor(.black, for: .normal)
    $0.setTitleColor(.systemGray, for: .disabled)
    $0.titleLabel?.font = .pretendard(size: 14)
  }

  private let titleTextField = UITextField().then {
    $0.borderStyle = .roundedRect
    $0.placeholder = "제목을 입력해 주세요"
    $0.borderStyle = .none
    $0.font = .pretendard(size: 20, weight: .semibold)
    $0.layer.borderWidth = 0
  }

  private let dividerView = UIView().then {
    $0.backgroundColor = .lightGray
  }

  private let textField = UITextView().then {
    $0.font = .pretendard(size: 16)
    $0.backgroundColor = .systemBackground
    $0.isScrollEnabled = true                           // 스크롤 가능 여부
    $0.showsVerticalScrollIndicator = false             // 수직 스크롤 바
    $0.keyboardDismissMode = .onDrag                    // 드래그 시 키보드 내려가기
    $0.autocorrectionType = .no                         // 자동 오타 수정 끄기
    $0.smartDashesType = .no                            // 스마트 대시 끄기
    $0.smartQuotesType = .no                            // 스마트 인용 부호 끄기
    $0.textDragInteraction?.isEnabled = true            // 드래그 앤 드롭 기능 활성화
  }

  init(reactor: WriteReactor) {
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
  }

  // UI 설정
  private func setUIConstraints() {
    [headerView, backButton, titleLabel, doneButton, titleTextField, dividerView, textField]
      .forEach { view.addSubview($0) }

    headerView.snp.makeConstraints {
      $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
      $0.leading.trailing.equalToSuperview()
      $0.height.equalTo(58)
    }

    backButton.snp.makeConstraints {
      $0.leading.equalToSuperview().offset(20)
      $0.centerY.equalTo(headerView.snp.centerY)
    }

    doneButton.snp.makeConstraints {
      $0.trailing.equalToSuperview().inset(20)
      $0.centerY.equalTo(headerView.snp.centerY)
    }

    titleLabel.snp.makeConstraints {
      $0.centerX.equalTo(headerView.snp.centerX)
      $0.centerY.equalTo(headerView.snp.centerY)
      $0.leading.greaterThanOrEqualTo(backButton.snp.trailing).offset(20)
      $0.trailing.lessThanOrEqualTo(doneButton.snp.leading).offset(-20)
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

    textField.snp.makeConstraints {
      $0.top.equalTo(dividerView.snp.bottom).offset(16)
      $0.leading.trailing.equalTo(titleTextField)
      $0.bottom.equalTo(view.safeAreaLayoutGuide)
    }
  }

  func bind(reactor: WriteReactor) {
    alert.leftTap
      .map { WriteReactor.Action.tapDismiss } // 왼쪽 버튼 눌리면 tapDismiss 액션으로 변환
      .bind(to: reactor.action)               // Reactor에 전달
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

    textField.rx.text.orEmpty
      .map { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
      .bind(to: doneButton.rx.isEnabled)
      .disposed(by: disposeBag)

    doneButton.rx.tap
      .map { WriteReactor.Action.tapDone }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)
  }
}
