//  AppStep.swift
//  Bragit
//
//  Created by 이태윤 on 8/25/25.
//
import Foundation

import RxFlow

enum AppStep: Step {
  // 공통
  case splash
  case dismiss                         // 닫기(present)
  case pop                             // 닫기(push)

  // 인증/가입
  case login                            // 로그인 화면 (최초 진입)
  case signupApple(refreshToken: String?, isAppleLogin: Bool)    // 애플 회원가입 시작
  case signupAppleNickname(refreshToken: String?)
  case signupAppleTerms(nickname: String, refreshToken: String?)         // 애플 약관 동의 (닉네임/리프레시 토큰 전달)
  case signupMailInfo
  case signupMailTerms(UserRegistrationInfo)
  case signupMailConfirm(UserRegistrationInfo)
  case signupImageUpload
  case signupTagSelect
  case signInMail                      // 메일 로그인
  case findPwd                         // 비밀번호 찾기
  case setPwd                          // 비밀번호 재설정

  // 홈
  case home                            // 메인 피드 루트

  // 검색
  case searchFeed                      // 피드 검색(선택적으로 쿼리 전달)

  // 피드 상세보기
  case feedDetail(post: Post)          // 피드 상세
  case comment(id: UUID)               // 댓글

  case userProfile(user: User)         // 타 유저 프로필 보기

  // 관심
  case favorite                        // 관심 피드 루트

  // 글쓰기
  case writeFeed                       // 글쓰기 루트
  case preview(draft: PostDraft)       // 미리보기
  case writeTagSearch                  // 태그 검색
  case tagPicked(tag: String)          // 태그 선택
  case updateFeed(post: PostUpdate)    // 글 수정

  // 마이페이지
  case myPage                          // 마이 루트
  case followersList([User])           // 팔로워 목록
  case followingList([User])           // 팔로잉 목록
  case favoriteList([Tag])             // 관심 태그 목록

  // 설정
  case setting                         // 설정
  case notification                    // 공지사항
  case terms                           // 이용 약관
  case termsDetails(TermsItem)         // 이용 약관 상세
  case service                         // 이용방법
  case report                          // 의견/오류 신고
  case openSource                      // 오픈소스 라이선스
  case openSourceDetails(LicenseItem)  // 오픈소스 라이선스 상세
  case cancelAccount                   // 탈퇴하기
  case blockUsers                      // 차단한 유저
  // 태그
  case tagInform(Tag)     // 태그 정보
}
