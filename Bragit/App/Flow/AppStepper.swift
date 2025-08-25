//
//  AppStepper.swift
//  Bragit
//
//  Created by 이태윤 on 8/25/25.
//
import RxFlow
import RxRelay

// 앱 전역에서 Step(이동 명령)을 방출하는 주체
// - initialStep: 앱 시작 시 가장 먼저 보낼 Step
// - steps: 외부에서 accept()하여 라우팅을 트리거하는 "공용 채널"
final class AppStepper: Stepper {
  // 코디네이터가 구독하는 이동 명령 스트림
  let steps = PublishRelay<Step>()

  // 앱 시작시 가장 먼저 보여줄 목적지
  var initialStep: Step { AppStep.login }

  // Helper
  func goToLogin() {
    steps.accept(AppStep.login)  // 로그인 화면으로
  }

  func goToTab(index: Int) {
    steps.accept(AppStep.tabBarSelected(index: index)) // 탭 전환
  }

  func goToHome() {
    steps.accept(AppStep.home) // 홈화면으로
  }

  func goToWrite() {
    steps.accept(AppStep.writeFeed) // 글쓰기 화면으로
  }

  func goMyPage() {
    steps.accept(AppStep.myPage) // 마이페이지로
  }

  func close() {
    steps.accept(AppStep.dismiss) // 닫기
  }
}
