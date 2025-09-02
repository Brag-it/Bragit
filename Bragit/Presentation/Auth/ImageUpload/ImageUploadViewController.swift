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
    $0.backgroundColor = UIColor.secondarySystemBackground
    $0.clipsToBounds = true
    $0.imageView?.contentMode = .scaleAspectFill
    let config = UIImage.SymbolConfiguration(pointSize: 44, weight: .regular)
    let placeholder = UIImage(systemName: "person", withConfiguration: config)
    $0.setImage(placeholder, for: .normal)
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
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "회원가입"
    view.backgroundColor = .systemBackground
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

    [descriptionLabel, imageButton, beLaterButton, nextButton].forEach {
      view.addSubview($0)
    }

    descriptionLabel.snp.makeConstraints {
      $0.top.equalTo(view.safeAreaLayoutGuide).offset(32)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    imageButton.snp.makeConstraints {
      $0.top.equalTo(descriptionLabel.snp.bottom).offset(32)
      $0.centerX.equalToSuperview()
      $0.width.height.equalTo(150)
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
  }
}

extension ImageUploadViewController {
  func bind(reactor: ImageUploadReactor) {

    imageButton.rx.tap
      .bind(with: self) {owner, _ in
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

    reactor.state
      .map(\.isLoading)
      .distinctUntilChanged()
      .bind(with: self) { owner, loading in
        owner.view.isUserInteractionEnabled = !loading
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
    }

    picker.dismiss(animated: true, completion: nil)
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true, completion: nil)
  }
}
