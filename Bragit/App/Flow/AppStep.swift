//  AppStep.swift
//  Bragit
//
//  Created by 이태윤 on 8/25/25.
//
import RxFlow

enum AppStep: Step {
  // 공통
  case dismiss                         // 닫기(present)
  case pop                             // 닫기(push)

  // 인증/가입
  case login                           // 로그인 화면 (최초 진입)
  case signup(initialMail: String?)    // 회원가입 시작
  case signTermsConset                 // 약관 동의
  case signServiceConsent              // 서비스 이용 약관 동의
  case signPersonalInfoConsent         // 개인정보 수집 동의
  case signMarketingConsent            // 마케팅 정보 수집 동의
  case signupPhoto                     // 프로필 사진 설정
  case signSelectTag(profileURL: String?)                   // 선호 태그 선택
  case findPwd                         // 비밀번호 찾기
  case setPwd                          // 비밀번호 재설정

  // 홈
  case home                            // 메인 피드 루트
  case feedDetail(id: String)          // 피드 상세
  case searchFeed(query: String?)      // 피드 검색(선택적으로 쿼리 전달)

  // 관심
  case favorite                        // 관심 피드 루트

  // 글쓰기
  case writeFeed                       // 글쓰기 루트
  case preview(draft: PostDraft)       // 미리보기
  case writeTagSearch                  // 태그 검색
  case tagPicked(tag: String)          // 태그 선택
  case updateFeed(id: String)          // 글 수정

  // 마이페이지
  case myPage                          // 마이 루트
  case followersList                   // 팔로워 목록
  case followingList                   // 팔로잉 목록
  case favoriteList                    // 관심 태그 목록

  // 설정
  case setting                         // 설정
  case notification                    // 공지사항
  case personalInfo                    // 개인정보 수집 방침
  case marketing                       // 마케팅 정보 수집 방침
  case service                         // 이용방법
  case report                          // 의견/오류 신고
  case openSource                      // 오픈소스 라이선스
}
