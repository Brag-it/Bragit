//
//  AppStep.swift
//  Bragit
//
//  Created by 이태윤 on 8/25/25.
//
import RxFlow

enum AppStep: Step {
  // 로그인 관련
  case initial                     // 최초 화면
  case login                       // 로그인 화면
  case signup                      // 회원가입 화면
  case signServiceAgree            // 서비스 이용 약관동의 화면
  case signInfoAgree               // 개인 정보 수집 동의 화면
  case signMarketingAgree          // 마케팅 정보 수집 동의 화면
  case signSelectTag               // 선호 태그 선택 화면
  case signupPhoto                 // 회원가입시 프로필사진 세팅 화면
  case findPwd                     // 비밀번호 찾기
  case setPwd                      // 비밀번호 재설정
  // 탭바 관련
  case tabBarSelected(index: Int)  // 탭바 선택
  // 홈 관련
  case home                        // 메인 피드 화면
  case feedDetail(id: String)      // 상세 글 화면
  case searchFeed                  // 글 검색 결과 화면
  // 관심 관련
  case favorite                    // 관심 피드 화면
  // 글쓰기 관련
  case writeFeed                   // 글쓰기 화면
  case preview                     // 미리보기 화면
  case wirteTagSearch              // 글쓰기 태그 검색 화면
  case updateFeed                  // 글 수정 화면
  // 마이페이지 관련
  case myPage                      // 마이페이지 화면
  case followList                  // 팔로워 화면
  case followerList                // 팔로잉 화면
  case favoriteList                // 관심 태그 화면
  case tempFeedList                // 임시저장 글 리스트
  // 설정 관련
  case setting                     // 설정 화면
  case notification                // 공지사항 화면
  case personalInfo                // 개인정보 수집 방침 화면
  case marketing                   // 마케팅 정보 수집 방침 화면
  case service                     // 이용방법 화면
  case report                      // 의견 보내기/ 오류 신고 화면
  case openSource                  // 오픈소스 라이선스 화면
  case appVersion                  // 앱 버전 화면
  // 닫기
  case dismiss
}
