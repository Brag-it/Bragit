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
  case signupApple(initialMail: String?, refreshToken: String?, isAppleLogin: Bool)    // 애플 회원가입 시작
  case signupMailInfo
  case signupMailTerms
  case signupMailConfirm
  case signupImageUpload
  case signupTagSelect
  // case signupMailInput                  // 인증을 위한 메일 입력
  // case signupMailConfirm                // 메일 회원가입 인증 요청
  // case signupMail                       // 메일 회원가입 시작
  // case signTermsConset                 // 약관 동의
  // case signServiceConsent              // 서비스 이용 약관 동의
  // case signPersonalInfoConsent         // 개인정보 수집 동의
  // case signMarketingConsent            // 마케팅 정보 수집 동의
  // case signupPhoto                     // 프로필 사진 설정
  // case signSelectTag(profileURL: String?)                   // 선호 태그 선택
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

  // 태그
  case tagInform(Tag)     // 태그 정보
}
