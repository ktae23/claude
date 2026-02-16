---
name: make-team
description: 프로젝트 목적을 받고, 역할별 에이전트 팀을 구성하는 팀메이킹 템플릿입니다.
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, Task, TeamCreate, TaskCreate, TaskUpdate, TaskList, TaskGet, SendMessage, TeamDelete
---

# /make-team — 팀메이킹 템플릿

프로젝트 목적에 맞는 에이전트 팀을 구성하는 **범용 팀 빌더**입니다.
사용자가 목적을 설명하면, 적합한 역할을 추천하고 팀을 만들어 작업을 시작합니다.

## 실행 흐름

### Step 1. 목적 파악

`/make-team` 뒤에 오는 텍스트를 프로젝트 목적으로 파악합니다.
목적이 없으면 **AskUserQuestion**으로 질문합니다:

- header: "목적"
- question: "어떤 프로젝트/작업을 위한 팀을 만들까요?"
- options:
  - "웹 서비스 개발" — 프론트엔드+백엔드+기획 중심
  - "콘텐츠/문서 작성" — 기획+리서치+작성 중심
  - "서비스 런칭" — 기획+마케팅+디자인+개발 풀팀

### Step 2. 팀 이름 결정

**AskUserQuestion**으로 팀 이름을 받습니다:

- header: "팀 이름"
- question: "팀 이름을 정해주세요. (영문 소문자, 하이픈 허용)"
- options:
  - 목적에서 유추한 이름 추천 2개
  - "직접 입력"

### Step 3. 에이전트 역할 선택

아래 역할 풀에서 **AskUserQuestion** (multiSelect: true)으로 선택받습니다:

- header: "팀 구성"
- question: "팀에 포함할 역할을 선택해주세요."

#### 역할 풀

| 역할 | 에이전트명 | subagent_type | 설명 |
|---|---|---|---|
| **기획자** | planner | general-purpose | PRD, 요구사항 분석, 기능 설계, 우선순위 결정 |
| **프론트엔드** | frontend-dev | general-purpose | UI/UX 구현, 컴포넌트, 스타일링, API 연동 |
| **백엔드** | backend-dev | general-purpose | API 설계, 도메인 로직, DB, 인프라 |
| **디자이너** | designer | general-purpose | 디자인 시스템, 와이어프레임, 프로토타입 |
| **마케터** | marketer | general-purpose | GTM 전략, SEO, 브랜딩, 카피라이팅 |
| **리서처** | researcher | general-purpose | 시장 조사, 경쟁 분석, 기술 리서치, 벤치마킹 |
| **테스터** | tester | general-purpose | 테스트 전략, 테스트 코드 작성, QA |
| **테크 라이터** | tech-writer | general-purpose | 기술 문서, API 문서, 사용자 가이드 |

**목적에 따른 추천 조합** (옵션 순서로 추천 표시):
- 웹 서비스 개발 → 기획자, 프론트엔드, 백엔드 (추천)
- 콘텐츠/문서 → 기획자, 리서처, 테크 라이터 (추천)
- 서비스 런칭 → 기획자, 마케터, 디자이너, 프론트엔드, 백엔드 (추천)

AskUserQuestion의 options 제한(최대 4개)에 맞춰, 목적에 가장 적합한 역할 3~4개를 옵션으로 제시합니다. 나머지 역할은 "Other"를 통해 선택할 수 있다고 안내합니다.

### Step 4. 프로젝트 경로 확인

**AskUserQuestion**으로 작업 디렉토리를 확인합니다:

- header: "경로"
- question: "프로젝트 작업 경로를 선택해주세요."
- options:
  - "~/Desktop/{팀이름}" (Recommended)
  - "현재 디렉토리"
  - "직접 입력"

### Step 5. 팀 생성 & 작업 시작

선택된 정보를 바탕으로:

1. **TeamCreate** 호출 (team_name: 사용자가 정한 이름)
2. 선택된 역할별로 **TaskCreate**로 초기 태스크 생성
3. 각 역할에 대해 **Task** 서브에이전트를 생성 (run_in_background: true, mode: bypassPermissions)
4. 프로젝트 디렉토리가 없으면 생성

#### 에이전트 프롬프트 템플릿

각 서브에이전트에게 전달하는 프롬프트에 반드시 포함할 내용:

```
당신은 "{팀이름}" 팀의 {역할명}입니다.

## 프로젝트 정보
- 목적: {사용자가 설명한 목적}
- 작업 경로: {프로젝트 경로}

## 당신의 담당
{역할별 담당 설명}

## 규칙
- 작업 시작 전 TaskGet으로 태스크 상세를 확인하세요
- 작업 완료 시 TaskUpdate로 상태를 completed로 변경하세요
- 다른 팀원과 협업이 필요하면 SendMessage를 사용하세요
- 결과물은 프로젝트 경로 내에 작성하세요
```

### Step 6. 모니터링 & 보고

- **TaskList**로 진행 상황을 주기적으로 확인
- 모든 태스크 완료 시 결과를 종합하여 사용자에게 보고
- 작업 완료 후 **SendMessage**(shutdown_request)로 팀원 종료 → **TeamDelete**

## 핵심 규칙

1. **직접 코드 작성 금지** — 모든 구현은 Task 서브에이전트를 통해 수행
2. **병렬 실행** — 독립 작업은 반드시 병렬로 Task 호출
3. **순차 실행** — 의존 관계 있는 작업은 선행 완료 후 실행
4. **컨텍스트 전달** — 각 에이전트에게 목적, 경로, 역할을 반드시 포함
5. **mode: bypassPermissions** — 모든 Task에 적용
6. **run_in_background: true** — 모든 Task를 백그라운드로 실행

## 사용 예시

```
/make-team 가족 소통 플랫폼을 만들고 싶어
→ 팀 이름: gagahoho
→ 역할 선택: 기획자, 프론트엔드, 백엔드, 디자이너
→ 경로: ~/Desktop/gagahoho
→ 팀 생성 완료! 4명의 에이전트가 작업을 시작합니다...

/make-team 블로그 글 10개 작성
→ 팀 이름: blog-content
→ 역할 선택: 기획자, 리서처, 테크 라이터
→ 경로: ~/Desktop/blog-content
→ 팀 생성 완료! 3명의 에이전트가 작업을 시작합니다...
```
