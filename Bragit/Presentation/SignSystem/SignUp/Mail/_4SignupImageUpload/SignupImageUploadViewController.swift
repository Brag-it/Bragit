//
//  SignupImageUploadViewController.swift
//  Bragit
//
//  Created by luca on 9/17/25.
//

import ReactorKit
import RxCocoa
import RxSwift
import UIKit

// 이메일 가입 4단계
// 가입자에게 프로필 사진 등록에 대한 선택권을 줌

final class SignupImageUploadViewController: UIViewController, View {
  var disposeBag = DisposeBag()
  private let rootView = SignupImageUploadView()

  override func loadView() {
    self.view = rootView
  }

  init(reactor: SignupImageUploadReactor) {
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(true, animated: false)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    rootView.imagePicker.delegate = self
  }

  func bind(reactor: SignupImageUploadReactor) {
    rootView.backButton.rx.tap
      .map { .tapBack }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    rootView.imageButton.rx.tap
      .bind(with: self) { owner, _ in
        owner.present(owner.rootView.imagePicker, animated: true)
      }
      .disposed(by: disposeBag)

    rootView.beLaterButton.rx.tap
      .map { .tapLater }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    rootView.nextButton.rx.tap
      .map { .tapNext }
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
        print("[ImageUpload] isLoading=\(isLoading), interactionEnabled=\(!isLoading)")
      }
      .disposed(by: disposeBag)

    // 이미지 선택 여부
    let hasImage = reactor.state
      .map { $0.imageData != nil }
      .distinctUntilChanged()
      .share(replay: 1)

    // 선택 이미지 있으면 nextButton 활성
    Observable.combineLatest(hasImage, loading)
      .map { hasImage, isLoading in hasImage && !isLoading }
      .bind(to: rootView.nextButton.rx.isEnabled)
      .disposed(by: disposeBag)

    Observable.combineLatest(hasImage, loading)
      .map { hasImage, isLoading in (hasImage && !isLoading) ? 1.0 : 0.5 }
      .bind(with: self) { owner, alpha in
        owner.rootView.nextButton.alpha = alpha
      }
      .disposed(by: disposeBag)

    Observable.combineLatest(hasImage, loading)
      .map { hasImage, isLoading in !hasImage && !isLoading }
      .bind(to: rootView.beLaterButton.rx.isEnabled)
      .disposed(by: disposeBag)

    Observable.combineLatest(hasImage, loading)
      .map { hasImage, isLoading in (!hasImage && !isLoading) ? 1.0 : 0.5 }
      .bind(with: self) { owner, alpha in
        owner.rootView.beLaterButton.alpha = alpha
      }
      .disposed(by: disposeBag)

  }
}

extension SignupImageUploadViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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

    self.rootView.setSelectedImage(image)

    if let data = image.jpegData(compressionQuality: 0.8) {
      reactor?.action.onNext(.pickedImageData(data))
      print("[ImageUpload] imageData sent to reactor, size: \(data.count)")
    }
    picker.dismiss(animated: true, completion: nil)
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true, completion: nil)
  }
}

