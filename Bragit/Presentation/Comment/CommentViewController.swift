//
//  CommentViewController.swift
//  Bragit
//
//  Created by luca on 9/4/25.
//

import UIKit

import Kingfisher
import ReactorKit
import RxCocoa
import RxSwift
import SnapKit
import Then

final class CommentViewController: UIViewController, View {
  typealias Reactor = CommentReactor
  var disposeBag = DisposeBag()

  // MARK: UI
  private let reportAlert = AlertView.makeAlert(style: .reportComment)
  private let deleteAlert = AlertView.makeAlert(style: .deleteComment)
  private let commentSelfMenu = MenuView(items: ["삭제하기"])
  private let commentOtherMenu = MenuView(items: ["신고하기"])

  private let headerView = UIView()

  private let backButton = UIButton(type: .system).then {
    $0.setImage(.back, for: .normal)
    $0.tintColor = .grayScale900
  }

  private let headerLabel = UILabel().then {
    $0.text = "댓글"
    $0.font = .pretendard(size: 18, weight: .medium)
    $0.textColor = .grayScale900
    $0.textAlignment = .center
    $0.setContentHuggingPriority(.defaultLow, for: .horizontal)
  }

  private let tableView = UITableView(frame: .zero, style: .plain).then {
    $0.register(CommentCell.self, forCellReuseIdentifier: CommentCell.reuseID)
    $0.rowHeight = UITableView.automaticDimension
    $0.estimatedRowHeight = 100
    $0.tableFooterView = UIView()
    $0.separatorStyle = .none
    $0.backgroundColor = .white
    $0.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
    $0.keyboardDismissMode = .interactive
    $0.separatorStyle = .singleLine
    $0.separatorColor = .grayScale100
    $0.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
  }

  private let refreshControl = UIRefreshControl()
  private let activityIndicator = UIActivityIndicatorView(style: .large).then {
    $0.hidesWhenStopped = true
    $0.color = .primary400
  }

  private let commentTextView = UITextView()
  private let sendButton = UIButton(type: .custom)

  private lazy var dismissTapGesture: UITapGestureRecognizer = {
    let tap = UITapGestureRecognizer()
    tap.cancelsTouchesInView = false
    tap.delegate = self
    return tap
  }()

  private let bottomBarTapButton = UIButton(type: .custom)
  private var menuTargetIndexPath: IndexPath?
  private var deleteCommentId: UUID?

  private let bottomSafeAreaBackground = UIView().then {
    $0.backgroundColor = .grayScale50
    $0.isUserInteractionEnabled = false
  }

  private var textContainerHeightConstraint: Constraint?
  private var bottomBarHeightConstraint: Constraint?

  private let lockImageView = UIImageView(image: .unlock).then {
    $0.contentMode = .scaleAspectFit
    $0.setContentHuggingPriority(.required, for: .horizontal)
    $0.setContentCompressionResistancePriority(.required, for: .horizontal)
  }
  private var textContainerLeadingWithLock: Constraint?
  private var textContainerLeadingWithoutLock: Constraint?

  private lazy var bottomBar: UIView = {
    let bar = UIView()
    bar.backgroundColor = .grayScale50

    let textContainer = UIView().then {
      $0.backgroundColor = .white
      $0.layer.cornerRadius = 12
      $0.layer.masksToBounds = true
    }

    let sendImageView = UIImageView(image: .send).then {
      $0.contentMode = .scaleAspectFit
      $0.isUserInteractionEnabled = false
      $0.setContentHuggingPriority(.required, for: .horizontal)
      $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    commentTextView.backgroundColor = .clear
    commentTextView.font = .pretendard(size: 15, weight: .regular)
    commentTextView.textColor = .grayScale900
    commentTextView.isScrollEnabled = false
    commentTextView.alwaysBounceVertical = true
    commentTextView.returnKeyType = .send
    commentTextView.enablesReturnKeyAutomatically = true
    commentTextView.delegate = self
    commentTextView.textContainer.lineBreakMode = .byWordWrapping
    commentTextView.textContainer.widthTracksTextView = true

    sendButton.backgroundColor = .clear
    bottomBarTapButton.backgroundColor = .clear

    bar.addSubview(lockImageView)
    bar.addSubview(textContainer)
    bar.addSubview(sendImageView)
    bar.addSubview(sendButton)
    textContainer.addSubview(commentTextView)
    textContainer.addSubview(bottomBarTapButton)

    let initialBarHalf: CGFloat = 27

    lockImageView.snp.makeConstraints {
      $0.leading.equalTo(bar.snp.leading).offset(12)
      $0.centerY.equalTo(bar.snp.bottom).offset(-initialBarHalf)
      $0.size.equalTo(CGSize(width: 20, height: 20))
    }

    textContainer.snp.makeConstraints {
      $0.trailing.equalTo(bar.snp.trailing).inset(12)
      $0.centerY.equalTo(bar.snp.centerY)
      self.textContainerHeightConstraint = $0.height.equalTo(42).constraint
    }

    self.textContainerLeadingWithLock =
      textContainer.snp.prepareConstraints {
        $0.leading.equalTo(self.lockImageView.snp.trailing).offset(10)
      }.first
    self.textContainerLeadingWithoutLock =
      textContainer.snp.prepareConstraints {
        $0.leading.equalTo(bar.snp.leading).offset(12)
      }.first
    self.textContainerLeadingWithoutLock?.activate()

    sendImageView.snp.makeConstraints {
      $0.trailing.equalTo(textContainer.snp.trailing).inset(12)
      $0.centerY.equalTo(bar.snp.bottom).offset(-initialBarHalf)
      $0.size.equalTo(CGSize(width: 20, height: 20))
    }

    sendButton.snp.makeConstraints {
      $0.center.equalTo(sendImageView)
      $0.size.equalTo(CGSize(width: 44, height: 44))
    }

    commentTextView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }

    bottomBarTapButton.snp.makeConstraints {
      $0.top.bottom.leading.equalToSuperview()
      $0.trailing.equalTo(sendImageView.snp.leading).offset(-8)
    }

    commentTextView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 34)

    bar.bringSubviewToFront(sendButton)

    updateLockVisibility(visible: false)

    return bar
  }()

  init(reactor: CommentReactor) {
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "댓글"
    view.backgroundColor = .white
    setupLayout()
    view.addGestureRecognizer(dismissTapGesture)

    // 초기 높이 보정
    adjustInputHeight(animated: false)
  }

  private func setupLayout() {
    view.addSubview(headerView)
    headerView.addSubview(backButton)
    headerView.addSubview(headerLabel)

    view.addSubview(bottomSafeAreaBackground)
    view.addSubview(tableView)
    view.addSubview(activityIndicator)
    view.addSubview(bottomBar)

    // 당겨서 새로고침
    tableView.refreshControl = refreshControl

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

    bottomBar.snp.makeConstraints {
      $0.leading.trailing.equalToSuperview()
      $0.bottom.equalTo(view.keyboardLayoutGuide.snp.top)
      self.bottomBarHeightConstraint = $0.height.equalTo(54).constraint
    }

    bottomSafeAreaBackground.snp.makeConstraints {
      $0.leading.trailing.equalToSuperview()
      $0.top.equalTo(bottomBar.snp.bottom)
      $0.bottom.equalTo(view.snp.bottom)
    }

    tableView.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom)
      $0.leading.trailing.equalToSuperview()
      $0.bottom.equalTo(bottomBar.snp.top)
    }

    activityIndicator.snp.makeConstraints {
      $0.center.equalTo(tableView)
    }
  }

  func bind(reactor: CommentReactor) {
    bindNavigation(reactor)
    bindInitialRefresh(reactor)
    bindPullToRefresh(reactor)
    bindBottomBarInteractions()
    bindSendButton(reactor)
    bindDismissTap()
    bindDeleteAlerts(reactor)
    bindComments(reactor)
    bindMenus()
    bindLoadingAndRefreshing(reactor)
    bindErrors(reactor)
    bindSendSuccessHandling(reactor)
  }

  // MARK: - Binding helpers (split to reduce cyclomatic complexity)

  private func bindNavigation(_ reactor: CommentReactor) {
    backButton.rx.tap
      .map { Reactor.Action.didTapBack }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)
  }

  private func bindInitialRefresh(_ reactor: CommentReactor) {
    rx.viewDidLoad
      .map { Reactor.Action.refresh }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)
  }

  private func bindPullToRefresh(_ reactor: CommentReactor) {
    tableView.rx.didEndDragging
      .filter { [weak self] _ in
        self?.refreshControl.isRefreshing == true
      }
      .map { _ in Reactor.Action.refresh }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)
  }

  private func bindBottomBarInteractions() {
    bottomBarTapButton.rx.tap
      .bind(with: self) { owner, _ in
        owner.commentTextView.becomeFirstResponder()
      }
      .disposed(by: disposeBag)
  }

  private func bindSendButton(_ reactor: CommentReactor) {
    sendButton.rx.tap
      .withLatestFrom(commentTextView.rx.text.orEmpty)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .map { Reactor.Action.sendComment($0) }
      .do { [weak self] _ in
        guard let self else { return }
        self.commentTextView.text = ""
        self.commentTextView.resignFirstResponder()
        self.adjustInputHeight(animated: true)
      }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)
  }

  private func bindDismissTap() {
    dismissTapGesture.rx.event
      .bind(with: self) { owner, _ in
        owner.view.endEditing(true)
      }
      .disposed(by: disposeBag)
  }

  private func bindDeleteAlerts(_ reactor: CommentReactor) {
    deleteAlert.rightTap
      .compactMap { [weak self] in self?.deleteCommentId }
      .do { [weak self] _ in self?.deleteCommentId = nil }
      .map { Reactor.Action.deleteComment($0) }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    deleteAlert.leftTap
      .bind { [weak self] in self?.deleteCommentId = nil }
      .disposed(by: disposeBag)
  }

  private func bindComments(_ reactor: CommentReactor) {
    reactor.state
      .map { $0.comments.sorted { $0.date > $1.date } }
      .observe(on: MainScheduler.instance)
      .bind(
        to: tableView.rx.items(
          cellIdentifier: CommentCell.reuseID,
          cellType: CommentCell.self
        )
      ) { [weak self, weak reactor] _, row, cell in
        guard let self, let reactor else { return }
        let nickname = (row.user?.nickname?.isEmpty == false) ? row.user!.nickname! : "탈퇴한 회원"
        let profileURL = row.user?.profile
        cell.configure(
          nickname: nickname,
          profileURLString: profileURL,
          date: row.date,
          content: row.content
        )

        let commenterId = row.commenterId ?? ""
        cell.profileTap
          .map { Reactor.Action.didTapUserProfile(commenterId) }
          .bind(to: reactor.action)
          .disposed(by: cell.disposeBag)

        cell.nameTap
          .map { Reactor.Action.didTapUserProfile(commenterId) }
          .bind(to: reactor.action)
          .disposed(by: cell.disposeBag)

        // 케밥 버튼 탭 시 메뉴 표시
        cell.kebabTap
          .bind { [weak self, weak cell] in
            guard let self, let cell else { return }

            let buttonFrameInView = cell.kebabButton.convert(cell.kebabButton.bounds, to: self.view)
            let menuWidth: CGFloat = 120
            let spacing: CGFloat = 8
            let sourcePoint = CGPoint(
              x: buttonFrameInView.maxX - menuWidth,
              y: buttonFrameInView.maxY + spacing
            )

            guard let indexPath = self.tableView.indexPath(for: cell) else { return }
            self.menuTargetIndexPath = indexPath

            let currentUserId = reactor.currentState.currentUserId?.trimmingCharacters(in: .whitespacesAndNewlines)
            let authorId = row.commenterId?.trimmingCharacters(in: .whitespacesAndNewlines)
            let isSelf = currentUserId?.lowercased() == authorId?.lowercased()

            if isSelf {
              self.commentSelfMenu.show(in: self.view, sourcePoint: sourcePoint)
            } else {
              self.commentOtherMenu.show(in: self.view, sourcePoint: sourcePoint)
            }
          }
          .disposed(by: cell.disposeBag)
      }
      .disposed(by: disposeBag)
  }

  private func bindMenus() {
    commentSelfMenu.itemTap
      .compactMap { $0 }
      .bind(with: self) { owner, index in
        guard index == 0, let targetIndexPath = owner.menuTargetIndexPath else { return }
        if let dataSource = owner.reactor?.currentState.comments.sorted(by: { $0.date > $1.date }),
          targetIndexPath.row >= 0, targetIndexPath.row < dataSource.count {
          owner.deleteCommentId = dataSource[targetIndexPath.row].id
          owner.deleteAlert.show(in: owner.view)
        } else {
          owner.deleteCommentId = nil
        }
      }
      .disposed(by: disposeBag)

    commentOtherMenu.itemTap
      .compactMap { $0 }
      .bind(with: self) { owner, index in
        guard index == 0, owner.menuTargetIndexPath != nil else { return }
        owner.reportAlert.show(in: owner.view)
      }
      .disposed(by: disposeBag)
  }

  private func bindLoadingAndRefreshing(_ reactor: CommentReactor) {
    reactor.state
      .map(\.isLoading)
      .distinctUntilChanged()
      .observe(on: MainScheduler.instance)
      .bind(with: self) { owner, loading in
        if loading {
          owner.activityIndicator.startAnimating()
        } else {
          owner.activityIndicator.stopAnimating()
          if owner.refreshControl.isRefreshing {
            owner.refreshControl.endRefreshing()
          }
          owner.tableView.reloadData()
        }
        owner.view.isUserInteractionEnabled = !loading
      }
      .disposed(by: disposeBag)
  }

  private func bindErrors(_ reactor: CommentReactor) {
    reactor.state
      .compactMap(\.errorMessage)
      .observe(on: MainScheduler.instance)
      .bind(with: self) { owner, message in
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "확인", style: .default))
        owner.present(alert, animated: true)
      }
      .disposed(by: disposeBag)
  }

  private func bindSendSuccessHandling(_ reactor: CommentReactor) {
    reactor.state
      .map(\.commentSent)
      .filter { $0 }
      .observe(on: MainScheduler.instance)
      .subscribe { [weak self] _ in
        guard let self else { return }
        self.commentTextView.text = ""
        self.adjustInputHeight(animated: true)

        if self.tableView.numberOfRows(inSection: 0) > 0 {
          self.tableView.scrollToRow(
            at: IndexPath(row: 0, section: 0),
            at: .top,
            animated: true
          )
        }
      }
      .disposed(by: disposeBag)
  }

  private func adjustInputHeight(animated: Bool) {
    view.layoutIfNeeded()

    let minHeight: CGFloat = 42  // 1줄 기본
    let verticalPadding: CGFloat = 12
    let insets = commentTextView.textContainerInset
    let lineHeight = commentTextView.font?.lineHeight ?? 17
    let maxTextHeight = (lineHeight * 3) + insets.top + insets.bottom

    let fittingWidth = max(0, commentTextView.bounds.width)
    let fittingSize = CGSize(width: fittingWidth, height: .greatestFiniteMagnitude)
    let calculated = commentTextView.sizeThatFits(fittingSize).height

    let targetTextHeight = min(maxTextHeight, max(minHeight, ceil(calculated)))
    let targetBarHeight = targetTextHeight + verticalPadding

    let shouldScroll = calculated > maxTextHeight + 0.5
    if commentTextView.isScrollEnabled != shouldScroll {
      commentTextView.isScrollEnabled = shouldScroll
    }

    textContainerHeightConstraint?.update(offset: targetTextHeight)
    bottomBarHeightConstraint?.update(offset: targetBarHeight)

    let updates = {
      self.view.layoutIfNeeded()
    }

    if animated {
      UIView.animate(withDuration: 0.2, animations: updates)
    } else {
      updates()
    }
    commentTextView.scrollRangeToVisible(commentTextView.selectedRange)
  }

  // MARK: - Lock 아이콘 노출/숨김에 따라 레이아웃 전환
  private func updateLockVisibility(visible: Bool, animated: Bool = false) {
    lockImageView.isHidden = !visible
    if visible {
      textContainerLeadingWithoutLock?.deactivate()
      textContainerLeadingWithLock?.activate()
    } else {
      textContainerLeadingWithLock?.deactivate()
      textContainerLeadingWithoutLock?.activate()
    }
    let updates = { self.view.layoutIfNeeded() }
    if animated {
      UIView.animate(withDuration: 0.2, animations: updates)
    } else {
      updates()
    }
  }
}

// MARK: - CommentCell
final class CommentCell: UITableViewCell {
  static let reuseID = "CommentCell"

  var disposeBag = DisposeBag()
  var kebabTap: ControlEvent<Void> { kebabButton.rx.tap }
  var profileTap: ControlEvent<Void> { profileImageView.rx.tap }
  var nameTap: ControlEvent<Void> { nameLabel.rx.tap }
  var kebabButtonFrameInCell: CGRect { kebabButton.frame }

  private let profileImageView = UIImageView().then {
    $0.contentMode = .scaleAspectFill
    $0.clipsToBounds = true
    $0.layer.cornerRadius = 18
    $0.backgroundColor = .secondarySystemBackground
    $0.snp.makeConstraints { $0.size.equalTo(CGSize(width: 36, height: 36)) }
    $0.isUserInteractionEnabled = true
  }

  private let nameLabel = UILabel().then {
    $0.font = .pretendard(size: 15, weight: .medium)
    $0.textColor = .label
    $0.numberOfLines = 1
    $0.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    $0.isUserInteractionEnabled = true
  }

  private let dateLabel = UILabel().then {
    $0.font = .pretendard(size: 13)
    $0.textColor = .secondaryLabel
    $0.textAlignment = .right
    $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    $0.setContentHuggingPriority(.required, for: .horizontal)
  }

  let kebabButton = UIButton(type: .system).then {
    $0.setImage(.kebab, for: .normal)
    $0.tintColor = .grayScale900
  }

  private let contentLabel = UILabel().then {
    $0.font = .pretendard(size: 15)
    $0.textColor = .label
    $0.numberOfLines = 0
  }

  private let headerContainer = UIView()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    setupLayout()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupLayout() {
    contentView.addSubview(headerContainer)
    contentView.addSubview(contentLabel)

    headerContainer.addSubview(profileImageView)
    headerContainer.addSubview(nameLabel)
    headerContainer.addSubview(kebabButton)
    headerContainer.addSubview(dateLabel)

    headerContainer.snp.makeConstraints {
      $0.top.equalToSuperview().offset(16)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.bottom.equalTo(profileImageView.snp.bottom)
    }

    profileImageView.snp.makeConstraints { $0.top.leading.equalToSuperview() }

    nameLabel.snp.makeConstraints {
      $0.leading.equalTo(profileImageView.snp.trailing).offset(6)
      $0.centerY.equalTo(profileImageView.snp.centerY)
    }

    kebabButton.snp.makeConstraints {
      $0.trailing.equalToSuperview()
      $0.centerY.equalTo(profileImageView.snp.centerY)
    }

    dateLabel.snp.makeConstraints {
      $0.trailing.equalTo(kebabButton.snp.leading).offset(-6)
      $0.centerY.equalTo(profileImageView.snp.centerY)
    }

    contentLabel.snp.makeConstraints {
      $0.top.equalTo(headerContainer.snp.bottom).offset(10)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.bottom.equalToSuperview().inset(16)
    }
  }

  func configure(
    nickname: String,
    profileURLString: String?,
    date: Date,
    content: String
  ) {
    nameLabel.text = nickname
    nameLabel.font = UIFont.pretendard(size: 15, weight: .medium)
    nameLabel.textColor = .black

    dateLabel.text = date.timeAgoDisplay()
    dateLabel.font = UIFont.pretendard(size: 13, weight: .regular)
    dateLabel.textColor = .grayScale400

    contentLabel.text = content
    contentLabel.font = UIFont.pretendard(size: 14, weight: .regular)
    contentLabel.textColor = .grayScale900

    if let urlString = profileURLString, let url = URL(string: urlString) {
      profileImageView.kf.setImage(with: url, placeholder: UIImage.profilePerson)
    } else {
      profileImageView.image = UIImage.profilePerson
    }
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    disposeBag = DisposeBag()
  }
}

extension CommentViewController: UITextViewDelegate {
  func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    if text == "\n" {
      let currentText = textView.text ?? ""
      let trimmedText = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
      if !trimmedText.isEmpty {
        reactor?.action.onNext(.sendComment(trimmedText))
        textView.text = ""
        textView.resignFirstResponder()
        adjustInputHeight(animated: true)
      }
      return false
    }
    return true
  }

  func textViewDidChange(_ textView: UITextView) {
    adjustInputHeight(animated: true)
  }
}

extension CommentViewController: UIGestureRecognizerDelegate {
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    if gestureRecognizer === dismissTapGesture {
      if touch.view is UIControl { return false }
      if touch.view?.isDescendant(of: bottomBar) == true { return false }
    }
    return true
  }
}

