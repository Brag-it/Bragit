//
//  DetailPostViewController.swift
//  Bragit
//
//  Created by 이태윤 on 9/4/25.
//
import UIKit
import PhotosUI

import ReactorKit
import RxSwift
import RxCocoa
import SnapKit
import Then
import Kingfisher
import Loaf

class DetailPostViewController: UIViewController, View {
  var disposeBag = DisposeBag()
  private let reportAlert = AlertView.makeAlert(style: .reportPost)
  private let deleteAlert = AlertView.makeAlert(style: .deletePost)
  private let differentMenu = MenuView(items: ["신고하기"])
  private let selfMenu = MenuView(items: ["삭제하기"])
  //  private let selfMenu = MenuView(items: ["수정하기", "삭제하기"])

  private let activityIndicator = UIActivityIndicatorView(style: .large).then {
    $0.hidesWhenStopped = true
    $0.color = .primary400
  }

  private let headerView = UIView()
  private let bottomView = UIView()

  private let backButton = UIButton(type: .system).then {
    $0.setImage(.back, for: .normal)
    $0.tintColor = .grayScale900
  }

  private let headerLabel = UILabel().then {
    $0.text = "게시물"
    $0.font = .pretendard(size: 18)
    $0.textColor = .grayScale900
    $0.textAlignment = .center
    $0.setContentHuggingPriority(.defaultLow, for: .horizontal)
  }

  private let kebabButton = UIButton(type: .system).then {
    $0.setImage(.kebab, for: .normal)
    $0.tintColor = .grayScale900
  }
  private let scrollView = UIScrollView()

  private let scrollContentView = UIView()

  private let titleView = UIView()

  private let uploadDateLabel = UILabel().then {
    $0.font = .pretendard(size: 13)
    $0.text = "몇분 전"
    $0.textColor = .grayScale400
  }

  private let titleLabel = UILabel().then {
    $0.numberOfLines = 0
    $0.font = .pretendard(size: 20, weight: .semibold)
  }

  private let profileImage = UIImageView().then {
    $0.contentMode = .scaleAspectFill
    $0.layer.cornerRadius = 18
    $0.clipsToBounds = true
    $0.kf.indicatorType = .activity // Kingfisher 인디케이터
  }

  private let nickNameLabel = UILabel().then {
    $0.font = .pretendard(size: 15, weight: .medium)
    $0.textColor = .grayScale900
  }

  private let followButton = UIButton(type: .system).then {
    $0.setTitle("팔로우", for: .normal)
    $0.titleLabel?.font = .pretendard(size: 16, weight: .medium)
    $0.setTitleColor(.grayScale900, for: .normal)
    $0.backgroundColor = .primary100
    $0.layer.cornerRadius = 12
  }

  private let dividerView = UIView().then {
    $0.backgroundColor = .grayScale100
  }

  private let contentView = UITextView().then {
    $0.isEditable = false
    $0.isScrollEnabled = false
    $0.textContainerInset = .zero
    $0.textContainer.lineFragmentPadding = 0
  }

  private let likeButton = UIButton(type: .system).then {
    let image = UIImage.favorite.resized(to: CGSize(width: 32, height: 32))
    $0.setImage(image, for: .normal)
    $0.tintColor = .grayScale900
  }

  private let likeCount = UILabel().then {
    $0.font = .pretendard(size: 16)
    $0.textColor = .grayScale600
  }

  private let commentButton = UIButton(type: .system).then {
    let image = UIImage.comment.resized(to: CGSize(width: 32, height: 32))
    $0.setImage(image, for: .normal)
    $0.tintColor = .grayScale900
  }

  init(reactor: DetailPostReactor) {
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white

    setUIConstraints()
  }

  // UI 설정
  private func setUIConstraints() {

    view.addSubview(headerView)
    headerView.addSubview(backButton)
    headerView.addSubview(headerLabel)
    headerView.addSubview(kebabButton)

    view.addSubview(scrollView)
    scrollView.addSubview(scrollContentView)
    scrollContentView.addSubview(titleView)
    scrollContentView.addSubview(contentView)

    scrollContentView.addSubview(activityIndicator)

    titleView.addSubview(uploadDateLabel)
    titleView.addSubview(titleLabel)
    titleView.addSubview(profileImage)
    titleView.addSubview(nickNameLabel)
    titleView.addSubview(followButton)
    titleView.addSubview(dividerView)

    view.addSubview(bottomView)
    bottomView.addSubview(likeButton)
    bottomView.addSubview(likeCount)
    bottomView.addSubview(commentButton)

    activityIndicator.snp.makeConstraints {
      $0.center.equalTo(contentView)
    }

    headerView.snp.makeConstraints {
      $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
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
      $0.trailing.lessThanOrEqualTo(kebabButton.snp.leading).offset(-20)
    }

    kebabButton.snp.makeConstraints {
      $0.trailing.equalToSuperview().inset(20)
      $0.centerY.equalTo(headerView.snp.centerY)
    }

    scrollView.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom)
      $0.leading.trailing.equalToSuperview()
      $0.bottom.equalTo(bottomView.snp.top)
    }

    scrollContentView.snp.makeConstraints {
      $0.directionalEdges.equalTo(scrollView.contentLayoutGuide)
      $0.width.equalTo(scrollView.frameLayoutGuide)
    }

    titleView.snp.makeConstraints {
      $0.top.equalToSuperview().inset(24)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    uploadDateLabel.snp.makeConstraints {
      $0.top.equalToSuperview()
      $0.leading.equalToSuperview()
    }

    titleLabel.snp.makeConstraints {
      $0.top.equalTo(uploadDateLabel.snp.bottom).offset(8)
      $0.leading.trailing.equalToSuperview()
    }

    profileImage.snp.makeConstraints {
      $0.top.equalTo(titleLabel.snp.bottom).offset(16)
      $0.leading.equalToSuperview()
      $0.width.height.equalTo(36)
    }

    nickNameLabel.snp.makeConstraints {
      $0.top.equalTo(profileImage)
      $0.centerY.equalTo(profileImage)
      $0.leading.equalTo(profileImage.snp.trailing).offset(12)
    }

    followButton.snp.makeConstraints {
      $0.top.equalTo(profileImage)
      $0.leading.greaterThanOrEqualTo(nickNameLabel.snp.trailing).offset(32)
      $0.trailing.equalToSuperview()
      $0.width.equalTo(66)
      $0.height.equalTo(40)
    }

    dividerView.snp.makeConstraints {
      $0.top.equalTo(followButton.snp.bottom).offset(18)
      $0.leading.trailing.equalToSuperview()
      $0.height.equalTo(1)
      $0.bottom.equalToSuperview()
    }

    contentView.snp.makeConstraints {
      $0.top.equalTo(dividerView.snp.bottom).offset(24)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.bottom.equalTo(scrollContentView.snp.bottom).inset(24)
    }

    bottomView.snp.makeConstraints {
      $0.bottom.equalTo(view.safeAreaLayoutGuide)
      $0.leading.trailing.equalToSuperview()
      $0.height.equalTo(52)
    }

    likeButton.snp.makeConstraints {
      $0.leading.equalToSuperview().offset(20)
      $0.centerY.equalTo(bottomView.snp.centerY)
    }

    likeCount.snp.makeConstraints {
      $0.leading.equalTo(likeButton.snp.trailing).offset(4)
      $0.centerY.equalTo(bottomView.snp.centerY)
    }

    commentButton.snp.makeConstraints {
      $0.trailing.equalToSuperview().offset(-20)
      $0.centerY.equalTo(bottomView.snp.centerY)
    }
  }

  // swiftlint:disable cyclomatic_complexity
  func bind(reactor: DetailPostReactor) {
    reportAlert.leftTap
      .bind { print("취소 버튼 누름") }
      .disposed(by: disposeBag)

    deleteAlert.leftTap
      .bind { print("취소 버튼 누름") }
      .disposed(by: disposeBag)

    reportAlert.rightTap
      .map { Reactor.Action.didTapReport }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    deleteAlert.rightTap
      .map { Reactor.Action.didTapDelete }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    // TODO: - 게시글 수정 구현 필요
    //    selfMenu.itemTap
    //      .bind { [weak self] index in
    //        guard let self else { return }
    //        if index == 0 {
    //          self.reactor?.action.onNext(.didTapEdit)
    //        } else if index == 1 {
    //          deleteAlert.show(in: view)
    //        }
    //      }
    //      .disposed(by: disposeBag)

    selfMenu.itemTap
      .bind { [weak self] index in
        guard let self else { return }
        if index == 0 {
          deleteAlert.show(in: view)
        }
      }
      .disposed(by: disposeBag)

    differentMenu.itemTap
      .bind { [weak self] index in
        guard let self else { return }
        if index == 0 {
          reportAlert.show(in: view)
        }
      }
      .disposed(by: disposeBag)

    backButton.rx.tap
      .map { Reactor.Action.didTapBack }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    kebabButton.rx.tap
      .bind { [weak self] in
        guard let self = self else { return }

        let buttonFrameInView = kebabButton.convert(kebabButton.bounds, to: view)

        let menuWidth: CGFloat = 120
        let spacing: CGFloat = 8

        let originX = buttonFrameInView.maxX - menuWidth
        let originY = buttonFrameInView.maxY + spacing
        let sourcePoint = CGPoint(x: originX, y: originY)

        if self.reactor?.currentState.viewer == true {
          selfMenu.show(in: view, sourcePoint: sourcePoint)
        } else {
          differentMenu.show(in: view, sourcePoint: sourcePoint)
        }
      }
      .disposed(by: disposeBag)

    profileImage.rx.tap
      .map { Reactor.Action.didTapUserProfile }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    nickNameLabel.rx.tap
      .map { Reactor.Action.didTapUserProfile }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    followButton.rx.tap
      .map { Reactor.Action.didTapFollow }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    likeButton.rx.tap
      .map { Reactor.Action.didTapLike }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    commentButton.rx.tap
      .map { Reactor.Action.didTapComment }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    reactor.state
      .take(1)
      .observe(on: MainScheduler.instance)
      .bind { [weak self] state in
        guard let self else { return }
        titleLabel.text = state.title
        nickNameLabel.text = state.nickName
        contentView.attributedText = state.content
        likeCount.text = String(state.likeCount)
        uploadDateLabel.text = reactor.post.date.timeAgoDisplay()
        if state.isLiked == true {
          let image = UIImage.favoriteFilled.resized(to: CGSize(width: 32, height: 32))
          likeButton.setImage(image, for: .normal)
          likeButton.tintColor = .systemDanger
        }
        if state.isfollowed == true {
          followButton.setTitle("팔로잉", for: .normal)
          followButton.backgroundColor = .grayScale100
        }
        if state.viewer == true || state.withdrewUser == true {
          followButton.isHidden = true
        }
        // 프로필 이미지 nil이면 기본 이미지 유지
        if let urlString = reactor.post.author?.profile, let url = URL(string: urlString) {
          profileImage.kf.setImage(
            with: url,
            options: [
              .transition(.fade(0.2)),
              .cacheOriginalImage
            ]
          )
        } else {
          profileImage.image = .profilePerson
          followButton.isHidden = true
        }
      }
      .disposed(by: disposeBag)

    reactor.state
      .bind { [weak self] state in
        guard let self else { return }
        likeCount.text = String(state.likeCount)
        likeButton.tintColor = state.isLiked ? .systemDanger : .grayScale900
        let image = if state.isLiked == true {
          UIImage.favoriteFilled.resized(to: CGSize(width: 32, height: 32))
        } else {
          UIImage.favorite.resized(to: CGSize(width: 32, height: 32))
        }
        likeButton.setImage(image, for: .normal)
        followButton.setTitle(state.isfollowed ? "팔로잉" : "팔로우", for: .normal)
        followButton.backgroundColor = state.isfollowed ? .grayScale100 : .primary100
      }
      .disposed(by: disposeBag)

    rx.viewDidLayoutSubviews
      .map { [weak self] in
        // 텍스트가 실제로 그려질 폭 계산
        guard let self = self else { return 0.0 }
        let width = contentView.textContainer.size.width
        return width > 0 ? width : contentView.bounds.width
      }
      .filter { $0 > 0 }   // 폭이 0이면 아직 레이아웃 전이기 때문에 스킵
      .take(1)
      .withLatestFrom(reactor.state.map(\.content).take(1)) { (maxWidth: $0, original: $1) }
      .do { [weak self] _ in
        guard let self = self else { return }
        activityIndicator.startAnimating()
        contentView.isHidden = true
      }
      .flatMapLatest { [weak self] pair -> Observable<NSAttributedString> in
        guard self != nil else { return .empty() }
        return Observable.create { observer in
          Task {
            let text = await DetailPostViewController.replaceLinksWithImages(in: pair.original, maxWidth: pair.maxWidth)
            observer.onNext(text)
            observer.onCompleted()
          }
          return Disposables.create()
        }
      }
      .observe(on: MainScheduler.instance)
      .do { [weak self] _ in
        guard let self = self else { return }
        activityIndicator.stopAnimating()
        contentView.isHidden = false
      }
      .bind(to: contentView.rx.attributedText)  // 치환 결과 적용
      .disposed(by: disposeBag)

    // 결과에 따른 토스트 표시
    reactor.pulse(\.$toast)
      .compactMap { $0 }
      .observe(on: MainScheduler.instance)
      .subscribe { [weak self] event in
        guard let self else { return }
        switch event.purpose {
        case .deleted:
          Loaf("삭제 되었어요!", state: .custom(.init(
            backgroundColor: .black,
            font: .pretendard(size: 14),
            icon: nil,
            textAlignment: .center,
            width: .screenPercentage(0.8))), sender: self).show()
        case .reported:
          Loaf("신고가 접수 되었어요!", state: .custom(.init(
            backgroundColor: .black,
            font: .pretendard(size: 14),
            icon: nil,
            textAlignment: .center)), sender: self).show()
        case .error(let message):
          Loaf("실패: \(message)", state: .custom(.init(
            backgroundColor: .black,
            font: .pretendard(size: 14),
            icon: nil,
            textAlignment: .center)), sender: self).show()
        case .blocked:
          break
        }
      }
      .disposed(by: disposeBag)
  }
  // swiftlint:enable cyclomatic_complexity

  static func replaceLinksWithImages(in attributed: NSAttributedString, maxWidth: CGFloat) async -> NSAttributedString {
    let mutable = NSMutableAttributedString(attributedString: attributed)
    var linkRanges: [(NSRange, URL)] = []

    attributed.enumerateAttribute(.link, in: NSRange(location: 0, length: attributed.length)) { value, range, _ in
      if let url = value as? URL { linkRanges.append((range, url)) }
    }
    guard !linkRanges.isEmpty else { return attributed }

    for (range, url) in linkRanges.reversed() { // 뒤에서부터 치환
      do {
        let result = try await KingfisherManager.shared.retrieveImage(with: url)
        let image = result.image
        let target = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        let fitted = image.kf.resize(to: target, for: .aspectFit)

        let attachment = NSTextAttachment()
        attachment.image = fitted
        let imgAttr = NSAttributedString(attachment: attachment)
        mutable.replaceCharacters(in: range, with: imgAttr)
      } catch {
        // 실패 시 링크 텍스트 그대로
        print("replaceLinksWithImages error:", error.localizedDescription)
      }
    }
    return mutable
  }
}
