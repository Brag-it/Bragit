# 브래깃(Bragit)

<img width="1280" alt="Thumbnail" src="https://github.com/user-attachments/assets/f098ad06-0e8b-4cee-97cb-c10a09868905" />

> **한줄 소개**
>
> `브래깃(Bragit)`은 사용자가 일상적 성취를 기록하고, 공유하며 커뮤니티와 상호작용할 수 있는 소셜 네트워크 애플리케이션입니다.
---

## 🎯 프로젝트 목적

* 사용자들이 작은 성취(작업 완료, 습관 달성, 일상 공유 등)를 쉽고 빠르게 기록하고 타인과 공유함으로써 동기 부여와 사회적 피드백을 제공받도록 하는 것을 목표로 합니다.

---

## ⏰ 프로젝트 개요

* **프로젝트 명**: Bragit
* **기간**: 2025.08.14. ~ 2025.09.19
* **팀 구성**: 디자인 1 / iOS 개발 3
* **디자인**: [Figma](https://www.figma.com/design/dQDRnSP6WvUddZtSgOBrlI/Bragit?node-id=19-752&t=6gxBhY8FONoe1PLe-1)

---

## ⚒️ Tech Stack

| 범위           | 기술/도구                                         |
| ------------ | --------------------------------------------- |
| 의존성 관리       | `Swift Package Manager (SPM)`                 |
| 형상 관리        | `Git`, `GitHub`                               |
| 아키텍처         | `ReactorKit` 기반 단방향 데이터 플로우                   |
| 디자인 패턴       | `Coordinator`, `Observer`, `State`            |
| UI           | `UIKit`                                       |
| 비동기/반응형      | `RxSwift`                                     |
| 레이아웃 / 유틸    | `SnapKit`, `Then`                             |
| 이미지/알림/애니메이션 | `Kingfisher`, `Loaf`, `Lottie`                |
| 로컬 저장소       | `UserDefaults` (간단한 캐시/설정용)                   |
| 서버 / DB      | `Supabase` (인증, DB, 스토리지)                     |
| 인증           | `Supabase Auth`, `Sign in with Apple`         |
| 코드 컨벤션       | `StyleShare - Swift Style Guide`, `SwiftLint` |

---

## 📱 미리보기 (Preview)

<img width="1250" alt="브로셔 이미지" src="https://github.com/user-attachments/assets/60d103ab-5512-4da5-8883-56684d22b06f" />

---

## 💡 주요 기능

📋 포스팅

- NSAttributedString 기반으로 글과 이미지, 다양한 서식을 자유롭게 조합해 나만의 포스트를 작성할 수 있어요.

🧑🏻‍💻 쉬운 로그인과 가입

- Sign in with Apple로 쉽고 빠르게 가입과 로그인을 할 수 있습니다.

🏷️ 태그 필터링

- 태그를 선택하여 태그 페이지로 이동하여 태그의 게시글을 볼 수 있습니다.
- 태그 페이지에서 하트 버튼을 눌러 관심 태그를 등록할 수 있습니다.
- 관심 탭에서 해당 태그들의 게시글을 필터링하여 볼 수 있습니다.

👀 피드 탐색

- 홈, 관심 탭에서 유저들의 다양한 피드를 확인하고, 게시글 상세로 이동할 수 있습니다.

👥 커뮤니티

- 유저간 팔로우를 통해 지속적으로 팔로잉한 사람의 게시글을 볼 수 있습니다.
- 댓글을 통해 유저들은 대화를 나눌 수 있습니다.

  
---

## 🔧 기술적 의사결정 및 근거

### ReactorKit

- 단방향 데이터 플로우를 이용해 View와 비즈니스 로직(State, Action, Mutation)를 분리하여 예측 가능한 상태로 관리하기 위해 사용

### RxSwift

- 비동기 이벤트에 대하여 반응적으로 대응하기 위해 사용

### RxFlow

- 수많은 화면에 대한 이동을 반응형으로 관리하기 위해 사용

### Supabase

- 게시글, 유저정보등 모든 유저에게 공유되어야 하는 데이터를 관리하기 위해 사용

### UserDefaults

- 로컬로 저장되는 데이터의 크기가 크지않다고 판단하여, 로컬 저장을 위해 UserDefault를 사용

---

## 🤯 트러블슈팅


---

## 📈 계획 (로드맵)

### 1차 (버전 1.0 준비)

* 사용자 테스팅 기반 버그 수정
* 핵심 UX/성능 개선
* 코드 리팩토링 및 테스트 추가

### 2차 (확장 기능)

* 소셜 로그인 추가(Google, Kakao 등)
* 포스팅 편집기 고도화(미디어 첨부, 멘션)
* 웹/백오피스 통합 관리 도구 도입

---

##  Git Flow & 브랜치 전략

* `main` : 배포용 안정화 브랜치 (릴리즈 태깅)
* `develop` : 통합 개발 브랜치
* `Feat/{번호}-{내용}` : 기능 브랜치
* `Chore/{번호}-{내용}` : 수정 브랜치
* `Fix/{번호}-{내용}` : 버그 브랜치
* `Docs/{번호}-{내용}` : 문서 브랜치
* `Refactor/{번호}-{내용}` : 리팩토링 브랜치
* `Add/{번호}-{내용}` : 추가 브랜치

---

## 📐 프로젝트 구조

```
Bragit/
├── App/
│   └── Flow/
│       - 앱의 전체적인 화면 흐름을 RxFlow를 통해 관리합니다.
│         (e.g., AppFlow, LoginFlow, TabFlow)
│
├── Presentation/
│   - 화면을 구성하는 UI(View, ViewController)와 상태를 관리하는 Reactor가 위치합니다.
│   - 각 화면 단위(e.g., Home, DetailPost)로 그룹화되어 있습니다.
│
├── Managers/
│   - 데이터 통신 및 비즈니스 로직을 담당하는 매니저 클래스가 위치합니다.
│   - Supabase API와 통신하여 데이터를 가져오거나(Repository 역할),
│     가공하여 Reactor에 전달합니다(UseCase 역할).
│     (e.g., PostManager, UserManager, AuthClient)
│
├── Model/
│   - 앱 전반에서 사용되는 데이터 모델(DTO)을 정의합니다.
│     (e.g., Post, User, Profile)
│
├── Util/
│   - 날짜 포맷팅, UI 확장 등 프로젝트 전반에서 사용되는
│     공통 유틸리티 및 Extension을 포함합니다.
│
└── Resources/
    - Assets, 폰트, Info.plist 등 앱에 필요한 리소스를 관리합니다.
```

---

## 👥 구성원 및 역할

* 이태윤: 포스팅, 검색, AppFlow, 게시글 상세 페이지, 기타 페이지, 공용컴포넌트
* 조성준: 홈, 관심, 마이페이지, 태그 상세페이지, 유저 상세 페이지, 팔로잉, DB구축, 유저 탈퇴
* 박범근: 소셜 로그인, 댓글
* 이신정: UI/UX 디자인 
