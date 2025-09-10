//
//  ImageUploadViewController.swift
//  Bragit
//
//  Created by luca on 8/27/25.
//

import UIKit

import ReactorKit
import RxCocoa
import RxSwift
import SnapKit
import Then

class ImageUploadViewController: UIViewController, View {
  typealias Reactor = ImageUploadReactor
  var disposeBag = DisposeBag()
  private let userInfo: UserRegistrationInfo
  private let injectReactor: ImageUploadReactor

  private let headerView = UIView()
  private let backButton = UIButton(type: .system).then {
    $0.setImage(.back, for: .normal)
    $0.tintColor = .grayScale900
  }
  private let headerLabel = UILabel().then {
    $0.text = "회원가입"
    $0.font = .pretendard(size: 18, weight: .medium)
    $0.textColor = .grayScale900
    $0.textAlignment = .center
    $0.setContentHuggingPriority(.defaultLow, for: .horizontal)
  }

  let descFont = UIFont.pretendard(size: 20, weight: .semibold)
  let beLaterFont = UIFont.pretendard(size: 16, weight: .regular)
  let nextFont = UIFont.pretendard(size: 16, weight: .medium)

  let primaryColor = UIColor(named: "primary400")
  let color900 = UIColor(named: "grayScale900")
  let color700 = UIColor(named: "grayScale700")

  init(userInfo: UserRegistrationInfo, reactor: ImageUploadReactor) {
    self.userInfo = userInfo
    self.injectReactor = reactor
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: UI
  let descriptionLabel = UILabel().then {
    $0.text = "나를 잘 나타내는 사진을 올려 볼까요?"
    $0.numberOfLines = 1
  }

  let imageButton = UIButton(type: .system).then {
    $0.setTitle(nil, for: .normal)
    $0.backgroundColor = UIColor.grayScale100
    $0.clipsToBounds = true
    $0.imageView?.contentMode = .center
    $0.tintColor = .grayScale600
    let placeholder = UIImage.mypage
      .resized(to: CGSize(width: 60, height: 60))
      .withRenderingMode(.alwaysTemplate)
    $0.setImage(placeholder, for: .normal)
  }

  let cameraButton = UIButton(type: .system).then {
    $0.setTitle(nil, for: .normal)
    $0.backgroundColor = .black
    $0.layer.cornerRadius = 24
    $0.layer.masksToBounds = true
    $0.layer.borderWidth = 1
    $0.layer.borderColor = UIColor.separator.cgColor
    $0.isUserInteractionEnabled = false
    $0.isAccessibilityElement = false

    let icon = UIImage.camera
      .resized(to: CGSize(width: 24, height: 24))
      .withRenderingMode(.alwaysTemplate)
    $0.setImage(icon, for: .normal)
    $0.tintColor = .white
    $0.imageView?.contentMode = .scaleAspectFill
  }

  let imagePicker = UIImagePickerController().then {
    $0.allowsEditing = true
  }

  lazy var beLaterButton = UIButton().then {
    $0.setTitle("나중에", for: .normal)
    $0.setTitleColor(color700, for: .normal)
    $0.backgroundColor = nil
  }

  lazy var nextButton = UIButton().then {
    $0.setTitle("다음", for: .normal)
    $0.setTitleColor(color900, for: .normal)
    $0.titleLabel?.font = nextFont
    $0.layer.cornerRadius = 12
    $0.backgroundColor = primaryColor
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    imageButton.layer.cornerRadius = 75
    cameraButton.layer.cornerRadius = 24
    view.bringSubviewToFront(cameraButton)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "회원가입"
    view.backgroundColor = .white
    self.reactor = injectReactor
    setupLayout()
    imagePicker.delegate = self
  }

  private func setupLayout() {
    descriptionLabel.font = descFont
    descriptionLabel.textColor = color900

    beLaterButton.backgroundColor = .none
    beLaterButton.titleLabel?.font = beLaterFont
    beLaterButton.titleLabel?.textColor = color700

    nextButton.backgroundColor = primaryColor
    nextButton.titleLabel?.font = nextFont
    nextButton.titleLabel?.textColor = color900

    view.addSubview(headerView)
    headerView.addSubview(backButton)
    headerView.addSubview(headerLabel)

    [descriptionLabel, imageButton, cameraButton, beLaterButton, nextButton].forEach {
      view.addSubview($0)
    }

    headerView.snp.makeConstraints {
      $0.top.equalTo(view.safeAreaLayoutGuide)
      $0.leading.trailing.equalToSuperview()
      $0.height.equalTo(58)
    }

    backButton.snp.makeConstraints {
      $0.leading.equalToSuperview().offset(20)
      $0.centerY.equalTo(headerView.snp.centerY)
    }

    headerLabel.snp.makeConstraints {
      $0.centerX.equalTo(headerView.snp.centerX)
      $0.centerY.equalTo(headerView.snp.centerY)
      $0.leading.greaterThanOrEqualTo(backButton.snp.trailing).offset(20)
    }

    descriptionLabel.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom).offset(32)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    imageButton.snp.makeConstraints {
      $0.top.equalTo(descriptionLabel.snp.bottom).offset(32)
      $0.centerX.equalToSuperview()
      $0.width.height.equalTo(150)
    }

    cameraButton.snp.makeConstraints {
      $0.width.height.equalTo(48)
      $0.trailing.equalTo(imageButton.snp.trailing)
      $0.bottom.equalTo(imageButton.snp.bottom)
    }

    beLaterButton.snp.makeConstraints {
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.bottom.equalTo(nextButton.snp.top).offset(-8)
      $0.height.equalTo(52)
    }

    nextButton.snp.makeConstraints {
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(24)
      $0.height.equalTo(52)
    }

    view.bringSubviewToFront(cameraButton)
  }
}

extension ImageUploadViewController {
  func bind(reactor: ImageUploadReactor) {
    backButton.rx.tap
      .map { Reactor.Action.tapBack }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    imageButton.rx.tap
      .bind(with: self) { owner, _ in
        owner.present(owner.imagePicker, animated: true)
      }
      .disposed(by: disposeBag)

    beLaterButton.rx.tap
      .map {
        ImageUploadReactor.Action.tapLater
      }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    nextButton.rx.tap
      .map { ImageUploadReactor.Action.tapNext }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    // 로딩 상태
    let loading = reactor.state
      .map(\.isLoading)
      .distinctUntilChanged()
      .share(replay: 1)

    loading
      .bind(with: self) { owner, isLoading in
        owner.view.isUserInteractionEnabled = !isLoading
        print("[UI] isLoading=\(isLoading), interactionEnabled=\(!isLoading)")
      }
      .disposed(by: disposeBag)

    // 이미지 선택 여부
    let hasImage = reactor.state
      .map { $0.imageData != nil }
      .distinctUntilChanged()
      .share(replay: 1)

    // 이미지가 있을 때 next 활성, 로딩 중엔 비활성
    Observable.combineLatest(hasImage, loading)
      .map { hasImage, isLoading in hasImage && !isLoading }
      .bind(to: nextButton.rx.isEnabled)
      .disposed(by: disposeBag)

    Observable.combineLatest(hasImage, loading)
      .map { hasImage, isLoading in (hasImage && !isLoading) ? 1.0 : 0.5 }
      .bind(with: self) { owner, alpha in
        owner.nextButton.alpha = alpha
      }
      .disposed(by: disposeBag)

    // 이미지가 없을 때 beLater 활성, 로딩 중엔 비활성
    Observable.combineLatest(hasImage, loading)
      .map { hasImage, isLoading in !hasImage && !isLoading }
      .bind(to: beLaterButton.rx.isEnabled)
      .disposed(by: disposeBag)

    Observable.combineLatest(hasImage, loading)
      .map { hasImage, isLoading in (!hasImage && !isLoading) ? 1.0 : 0.5 }
      .bind(with: self) { owner, alpha in
        owner.beLaterButton.alpha = alpha
      }
      .disposed(by: disposeBag)
  }
}

extension ImageUploadViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
  ) {
    let key: UIImagePickerController.InfoKey = .editedImage
    let fallback: UIImagePickerController.InfoKey = .originalImage
    guard let image = (info[key] as? UIImage) ?? (info[fallback] as? UIImage) else {
      picker.dismiss(animated: true, completion: nil)
      return
    }

    self.imageButton.setImage(nil, for: .normal)
    self.imageButton.setBackgroundImage(image, for: .normal)

    if let data = image.jpegData(compressionQuality: 0.8) {
      reactor?.action.onNext(.pickedImageData(data))
      print("[UI] picked imageData sent to reactor, size: \(data.count)")
    }

    picker.dismiss(animated: true, completion: nil)
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true, completion: nil)
  }
}
