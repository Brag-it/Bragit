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
  private let backAlert = AlertView.makeAlert(style: .tempSaveDraft)
  private let isEmptyAlert = AlertView.makeAlert(style: .isEmptyPost)
  private let loadPostAlert = AlertView.makeAlert(style: .loadPost)

  private let headerView = UIView()

  private let backButton = UIButton(type: .system).then {
    $0.setImage(.xMarker, for: .normal)
    $0.tintColor = .grayScale900
  }

  private let titleLabel = UILabel().then {
    $0.text = "글쓰기"
    $0.font = .pretendard(size: 18, weight: .medium)
    $0.textColor = .grayScale900
    $0.textAlignment = .center
    $0.setContentHuggingPriority(.defaultLow, for: .horizontal)
  }

  private let doneButton = UIButton(type: .system).then {
    $0.setTitle("완료", for: .normal)
    $0.setTitleColor(.grayScale900, for: .normal)
    $0.titleLabel?.font = .pretendard(size: 16)
  }

  private let titleTextField = UITextField().then {
    $0.placeholder = "제목을 입력해 주세요"
    $0.borderStyle = .none
    $0.font = .pretendard(size: 20, weight: .semibold)
  }

  private let dividerView = UIView().then {
    $0.backgroundColor = .grayScale100
  }

  private let editorView = EditorView()

  init(reactor: WriteReactor) {
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    self.navigationController?.isNavigationBarHidden = true
    setUIConstraints()
    reactor?.action.onNext(.isLoadPost)
  }

  // UI 설정
  private func setUIConstraints() {
    [headerView, backButton, titleLabel, doneButton, titleTextField, dividerView, editorView]
      .forEach { view.addSubview($0) }

    headerView.snp.makeConstraints {
      $0.top.equalTo(view.safeAreaLayoutGuide)
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
      $0.trailing.lessThanOrEqualTo(doneButton.snp.leading).offset(-20)
    }

    doneButton.snp.makeConstraints {
      $0.trailing.equalToSuperview().inset(20)
      $0.centerY.equalTo(headerView.snp.centerY)
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
      $0.bottom.equalTo(view.keyboardLayoutGuide.snp.top)
    }
  }

  func bind(reactor: WriteReactor) {
    backAlert.leftTap
      .map { Reactor.Action.tapDismiss }      // 왼쪽 버튼 눌리면 tapDismiss 액션으로 변환
      .bind(to: reactor.action)               // Reactor에 전달
      .disposed(by: disposeBag)

    backAlert.rightTap
      .map { Reactor.Action.tapTemporary } // 임시저장
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    loadPostAlert.leftTap
      .bind { [weak self] in
        guard let self else { return }
        
      }
      .disposed(by: disposeBag)

    loadPostAlert.rightTap
      .map { Reactor.Action.tapLoadPost } // 불러오기
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    reactor.state
      .map { $0.isLoadPost }
      .distinctUntilChanged()
      .filter { $0 }
      .bind { [weak self] _ in
        guard let self else { return }
        loadPostAlert.show(in: self.view)
      }
      .disposed(by: disposeBag)

    backButton.rx.tap
      .bind { [weak self] in
        guard let self else { return }
        let isTitleEmpty = titleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
        let isContentEmpty = editorView.textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if isTitleEmpty && isContentEmpty {
          reactor.action.onNext(.tapDismiss)
        } else {
          backAlert.show(in: self.view)
        }
      }
      .disposed(by: disposeBag)

    // 완료 버튼 탭
    doneButton.rx.tap
      .bind { [weak self] in
        guard let self else { return }

        let isTitleEmpty = titleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
        let isContentEmpty = editorView.textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if isTitleEmpty || isContentEmpty {
          isEmptyAlert.show(in: self.view)
        } else {
          reactor.action.onNext(.tapDone)
        }
      }
      .disposed(by: disposeBag)

    editorView.accessoryView.boldButton.rx.tap
      .map { Reactor.Action.boldTapped }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    editorView.accessoryView.underlineButton.rx.tap
      .map { Reactor.Action.underlineTapped }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    editorView.accessoryView.strikethroughButton.rx.tap
      .map { Reactor.Action.strikethroughTapped }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    editorView.accessoryView.imageButton.rx.tap
      .bind { [weak self] in
        guard let self else { return }
        presentImagePicker()
      }
      .disposed(by: disposeBag)

    editorView.accessoryView.keyboardDismissButton.rx.tap
      .bind { [weak self] in
        guard let self else { return }
        view.endEditing(true)
      }
      .disposed(by: disposeBag)

    titleTextField.rx.text.orEmpty
      .distinctUntilChanged()
      .map { Reactor.Action.updateTitle($0) }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    editorView.textView.rx.attributedText
      .compactMap { $0 }
      .distinctUntilChanged()
      .map { Reactor.Action.updateContent($0) }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    reactor.state
      .map { $0.title }
      .distinctUntilChanged()
      .bind(to: titleTextField.rx.text)
      .disposed(by: disposeBag)

    reactor.state
      .map { $0.content }
      .distinctUntilChanged()
      .bind { [weak self] content in
        guard let self else { return }
        self.editorView.textView.attributedText = content
        self.editorView.textView.layoutManager.ensureLayout(for: self.editorView.textView.textContainer)
      }
      .disposed(by: disposeBag)

    reactor.state
      .bind { [weak self] state in
        guard let self else { return }
        editorView.applyBold(state.isBoldActive)
        editorView.applyUnderline(state.isUnderlineActive)
        editorView.applyStrikethrough(state.isStrikethroughActive)
        editorView.accessoryView.boldButton.tintColor = state.isBoldActive ? .information : .grayScaleBack
        editorView.accessoryView.underlineButton.tintColor = state.isUnderlineActive ? .information : .grayScaleBack
        editorView.accessoryView.strikethroughButton.tintColor = state.isStrikethroughActive ?
          .information : .grayScaleBack
      }
      .disposed(by: disposeBag)
  }

  func presentImagePicker() {
    var config = PHPickerConfiguration()
    config.selectionLimit = 1
    config.filter = .images                    // 이미지 타입만
    let picker = PHPickerViewController(configuration: config)
    picker.delegate = self                     // 결과 콜백 받기

    present(picker, animated: true)
  }
}

extension WriteViewController: PHPickerViewControllerDelegate {
  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    dismiss(animated: true)

    guard let itemProvider = results.first?.itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) else {
      return
    }

    // 비동기로 UIImage 불러오기
    itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (obj, error) in
      guard let self, let image = obj as? UIImage, error == nil else { return }
      DispatchQueue.main.async {
        // 커서 위치에 이미지 삽입
        self.editorView.insertImage(image: image)
      }
    }
  }
}
