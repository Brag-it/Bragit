//
//  SignupTagSelectViewController.swift
//  Bragit
//
//  Created by luca on 9/17/25.
//

import Dependencies
import ReactorKit
import RxCocoa
import RxSwift
import UIKit

// 이메일 가입 5단계
// 가입자에게 관심있는 태그를 선택할 수 있는 선택지를 줌

final class SignupTagSelectViewController: UIViewController, View {
  var disposeBag = DisposeBag()

  private let rootView = SignupTagSelectView()
  @Dependency(\.tagManager) private var tagManager
  @LocalStorage(location: .favoriteTags) private var favoriteTags: [Tag]?

  override func loadView() {
    self.view = rootView
  }

  init(reactor: SignupTagSelectReactor) {
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
    loadTags()
  }

  func bind(reactor: SignupTagSelectReactor) {
    rootView.backButton.rx.tap
      .map { .tapBack }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    rootView.beLaterButton.rx.tap
      .map { .tapLater }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    rootView.nextButton.rx.tap
      .withUnretained(self)
      .map { owner, _ in
        let selectedIndexPaths = owner.rootView.tagCollectionView.indexPathsForSelectedItems ?? []
        let chosenModels: [Tag] = selectedIndexPaths
          .sorted { $0.item < $1.item }
          .map { owner.rootView.tags[$0.item] }
        owner.favoriteTags = chosenModels
        print("[SignupTagSelect] favoriteTags(models) -> \(chosenModels.map { $0.tag })")
        return SignupTagSelectReactor.Action.tapNext(tags: chosenModels)
      }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    // isLoading stream
    let loading = reactor.state
      .map { $0.isLoading }
      .distinctUntilChanged()
      .share(replay: 1)

    // Selection change events
    let selectionChanged = Observable.merge(
      rootView.tagCollectionView.rx.itemSelected.map { _ in () },
      rootView.tagCollectionView.rx.itemDeselected.map { _ in () }
    )
    .startWith(())
    .share(replay: 1)

    let hasSelection = selectionChanged
      .map { [weak self] in
        guard let self else { return false }
        let isEmpty = self.rootView.tagCollectionView.indexPathsForSelectedItems?.isEmpty ?? true
        return !isEmpty
      }
      .distinctUntilChanged()
      .share(replay: 1)

    // Disable interactions during loading
    loading
      .observe(on: MainScheduler.instance)
      .bind(with: self) { owner, isLoading in
        owner.view.isUserInteractionEnabled = !isLoading
      }
      .disposed(by: disposeBag)

    // nextButton enabled when selection exists and not loading
    Observable.combineLatest(hasSelection, loading)
      .map { has, isLoading in has && !isLoading }
      .bind(to: rootView.nextButton.rx.isEnabled)
      .disposed(by: disposeBag)

    Observable.combineLatest(hasSelection, loading)
      .map { has, isLoading in (has && !isLoading) ? 1.0 : 0.5 }
      .bind(with: self) { owner, alpha in
        owner.rootView.nextButton.alpha = alpha
      }
      .disposed(by: disposeBag)

    // beLaterButton enabled when no selection and not loading
    Observable.combineLatest(hasSelection, loading)
      .map { has, isLoading in !has && !isLoading }
      .bind(to: rootView.beLaterButton.rx.isEnabled)
      .disposed(by: disposeBag)

    Observable.combineLatest(hasSelection, loading)
      .map { has, isLoading in (!has && !isLoading) ? 1.0 : 0.5 }
      .bind(with: self) { owner, alpha in
        owner.rootView.beLaterButton.alpha = alpha
      }
      .disposed(by: disposeBag)
  }

  private func loadTags() {
    tagManager.rxFetchPopularTags()
      .observe(on: MainScheduler.instance)
      .subscribe(
        onNext: { [weak self] tags in
          guard let self else { return }
          self.rootView.tags = tags
          self.rootView.tagCollectionView.reloadData()
          if let selectedTags = self.favoriteTags?.map({ $0.tag }), !selectedTags.isEmpty {
            for (idx, tag) in self.rootView.tags.enumerated() where selectedTags.contains(tag.tag) {
              let indexPath = IndexPath(item: idx, section: 0)
              self.rootView.tagCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            }
            self.rootView.tagCollectionView.reloadData()
          }
        },
        onError: { error in
          print("[LoadTags] 태그 로딩 에러: \(error.localizedDescription)")
        }
      )
      .disposed(by: disposeBag)
  }
}
