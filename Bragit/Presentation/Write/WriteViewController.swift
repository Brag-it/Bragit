//
//  WriteViewController.swift
//  Bragit
//
//  Created by 이태윤 on 8/20/25.
//
import UIKit
import PhotosUI

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
    $0.placeholder = "제목을 입력해 주세요"
    $0.borderStyle = .none
    $0.font = .pretendard(size: 20, weight: .semibold)
  }

  private let dividerView = UIView().then {
    $0.backgroundColor = .lightGray
  }

  private let editorView = TestMarkDownEditorView()

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
    [headerView, backButton, titleLabel, doneButton, titleTextField, dividerView, editorView]
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

    editorView.snp.makeConstraints {
      $0.top.equalTo(dividerView.snp.bottom).offset(16)
      $0.leading.trailing.equalTo(titleTextField)
      $0.bottom.equalTo(view.safeAreaLayoutGuide)
    }
  }

  func bind(reactor: WriteReactor) {
    alert.leftTap
      .map { Reactor.Action.tapDismiss } // 왼쪽 버튼 눌리면 tapDismiss 액션으로 변환
      .bind(to: reactor.action)               // Reactor에 전달
      .disposed(by: disposeBag)

    alert.rightTap
      .bind { print("오른쪽 버튼 누름") }
      .disposed(by: disposeBag)

    backButton.rx.tap
      .bind { [weak self] in
        guard let self else { return }
        self.alert.show(in: self.view)
      }
      .disposed(by: disposeBag)

    // 완료 버튼 탭
    doneButton.rx.tap
      .map { Reactor.Action.doneButtonTapped }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    // 제목 텍스트 변경
    titleTextField.rx.text.orEmpty
      .map { Reactor.Action.titleDidChange($0) }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    // 에디터 내용 변경
    editorView.coreTextView.rx.didChange
      .withLatestFrom(editorView.coreTextView.rx.attributedText)
      .map { Reactor.Action.contentDidChange($0 ?? NSAttributedString(string: "")) }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    // 볼드 버튼 탭
    editorView.boldButtonTap
      .map { Reactor.Action.boldButtonTapped }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    // 이미지 버튼 탭
    editorView.imageButtonTap
      .map { Reactor.Action.imageButtonTapped }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    // 완료 버튼 활성화 여부
    reactor.state.map { $0.canPost }
      .distinctUntilChanged()
      .bind(to: doneButton.rx.isEnabled)
      .disposed(by: disposeBag)

    // 이미지 피커 표시: shouldShowImagePicker가 true가 되는 순간만 감지하여 실행
    reactor.state.map { $0.shouldShowImagePicker }
      .distinctUntilChanged()
      .filter { $0 == true }
      .bind { [weak self] _ in
        self?.presentImagePicker()
      }
      .disposed(by: disposeBag)

    // 볼드 속성 토글: shouldToggleBold가 true가 되는 순간만 감지하여 실행
    reactor.state.map { $0.shouldToggleBold }
      .distinctUntilChanged()
      .filter { $0 == true }
      .bind { [weak self] _ in
        self?.toggleBold()
      }
      .disposed(by: disposeBag)

    // 이미지 삽입: imageToInsert에 값이 들어오는 순간만 감지하여 실행
    reactor.state.compactMap { $0.imageToInsert }
      .distinctUntilChanged()
      .bind { [weak self] image in
        self?.editorView.insertImage(image: image)
      }
      .disposed(by: disposeBag)
  }

  // MARK: - Private Methods

  // 볼드 토글 로직: ViewController가 에디터의 현재 상태를 보고 어떤 메서드를 호출할지 결정합니다.
  private func toggleBold() {
    let selectedRange = editorView.coreTextView.selectedRange
    if selectedRange.length == 0 {
      editorView.toggleTypingAttribute(fontTrait: .traitBold)
    } else {
      editorView.toggleSelectionAttribute(fontTrait: .traitBold)
    }
  }

  // 이미지 피커를 띄웁니다.
  private func presentImagePicker() {
    var config = PHPickerConfiguration()
    config.selectionLimit = 1 // 한 번에 하나의 이미지만 선택
    config.filter = .images // 이미지만 선택하도록 필터링
    let picker = PHPickerViewController(configuration: config)
    picker.delegate = self
    present(picker, animated: true)
  }
}

// MARK: - PHPickerViewControllerDelegate
extension WriteViewController: PHPickerViewControllerDelegate {
  // 이미지 선택이 완료되었을 때 호출되는 델리게이트 메서드입니다.
  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    // 피커를 닫습니다.
    picker.dismiss(animated: true)

    // 사용자가 선택한 이미지가 있는지 확인합니다.
    guard let result = results.first else { return }
    // 선택된 이미지 데이터를 로드합니다.
    result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
      guard let self = self, let image = image as? UIImage else { return }
      // 로드가 완료되면, 메인 스레드에서 Reactor에 imageDidPick 액션을 전달합니다.
      DispatchQueue.main.async {
        self.reactor?.action.onNext(.imageDidPick(image))
      }
    }
  }
}
