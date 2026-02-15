---
name: curriculum
description: 주어진 주제를 분석하여 커리큘럼을 설계하고, 서브에이전트 팀으로 학습 문서를 병렬 작성합니다.
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, Task, TeamCreate, TeamDelete, TaskCreate, TaskUpdate, TaskList, TaskGet, SendMessage, EnterPlanMode, ExitPlanMode
---

# /curriculum — 학습 커리큘럼 자동 생성기

주어진 주제를 분석하여 체계적인 커리큘럼을 설계하고, 병렬 서브에이전트 팀을 통해 학습 문서를 자동 작성합니다.

## 실행 흐름

### Phase 1. 주제 및 설정 수집

**AskUserQuestion**으로 다음 정보를 순차적으로 수집합니다:

#### Step 1. 주제 입력
- header: "주제"
- question: "커리큘럼을 작성할 주제를 입력해주세요."
- options:
  - 사용자 입력 예시 2~3개 (기술 스택 관련)
- 사용자가 "Other"를 선택하면 직접 입력

#### Step 2. 참조 소스코드 (선택)
- header: "소스코드"
- question: "분석할 소스코드 경로가 있나요? (없으면 '없음' 선택)"
- options:
  - "없음": 공식 문서와 지식 기반으로만 작성
  - "GitHub Clone": GitHub 레포를 clone하여 분석
- 사용자가 "Other"를 선택하면 로컬 경로 입력
- "GitHub Clone" 선택 시:
  - 추가 AskUserQuestion으로 GitHub URL 입력받기
  - `/tmp/{repo-name}/`에 clone 실행

#### Step 3. 출력 경로
- header: "경로"
- question: "커리큘럼 문서를 저장할 경로를 선택해주세요."
- options:
  - "$TIL_ROOT/{주제-kebab-case}/" (Recommended)
- 사용자가 "Other"를 선택하면 직접 경로 입력

#### Step 4. 커리큘럼 규모
- header: "규모"
- question: "커리큘럼 규모를 선택해주세요."
- options:
  - "소형 (6~8문서)": 핵심 개념 중심 빠른 학습
  - "중형 (12~16문서)": 심화 학습 포함 (Recommended)
  - "대형 (20~24문서)": 투트랙(원리+실무) 종합 커리큘럼

#### Step 5. 문서 언어
- header: "언어"
- question: "문서 본문 언어를 선택해주세요."
- options:
  - "한국어 (코드는 영어)": 한국어 설명 + 영어 코드/클래스명 (Recommended)
  - "영어": 전체 영어
- 사용자가 "Other"를 선택하면 직접 지정

### Phase 2. 커리큘럼 설계

수집된 정보를 바탕으로 커리큘럼을 설계합니다.

1. **소스코드 분석** (소스코드 경로가 있는 경우):
   - Task(subagent_type: "Explore")로 프로젝트 구조, 핵심 클래스, 아키텍처 패턴 분석
   - 분석 결과를 커리큘럼 소재로 활용

2. **커리큘럼 구조 설계**:
   규모에 따라 트랙 구성:
   - 소형: 단일 트랙 (6~8문서)
   - 중형: 단일 트랙 또는 2트랙 (12~16문서)
   - 대형: 2트랙 — main/(동작원리) + advanced/(실무 활용) (20~24문서)

3. **문서 목록 확정**:
   각 문서에 대해 결정:
   - 파일명 (kebab-case, 번호 접두사)
   - 제목 (한국어)
   - 핵심 내용 요약 (3~5줄)
   - 참조 소스코드 클래스/메서드 (있는 경우)
   - 의존 관계 (선행 학습 문서)

4. **계획서 출력**:
   설계된 커리큘럼을 마크다운 형식으로 사용자에게 출력:
   ```
   ## 커리큘럼: {주제}

   ### 디렉토리 구조
   {tree 형식}

   ### 문서 목록
   | # | 파일명 | 제목 | 핵심 내용 |
   |---|--------|------|----------|
   | 1 | xxx.md | ... | ... |

   ### 의존 관계
   {dependency diagram}
   ```

5. **사용자 승인**:
   - AskUserQuestion으로 최종 확인
   - header: "확인"
   - question: "위 커리큘럼으로 문서를 작성할까요?"
   - options:
     - "시작": 작성 시작
     - "수정": 커리큘럼 수정 요청
     - "취소": 작업 취소

### Phase 3. 병렬 문서 작성

승인 후 팀을 구성하여 병렬로 문서를 작성합니다.

1. **디렉토리 생성**:
   ```bash
   mkdir -p {출력_경로}/{트랙별_하위_디렉토리}
   ```

2. **팀 생성**:
   ```
   TeamCreate: {주제}-curriculum
   ```

3. **태스크 분배**:
   - 총 문서 수를 4개씩 묶어 태스크 생성 (TaskCreate)
   - 예: 24문서 → 6태스크 (4문서/태스크)
   - 예: 12문서 → 3태스크 (4문서/태스크)
   - 예: 8문서 → 2태스크 (4문서/태스크)

4. **에이전트 스폰**:
   태스크 수만큼 writer 에이전트를 **동시에** 스폰합니다:
   ```
   Task(
     name: "writer-{n}",
     subagent_type: "general-purpose",
     team_name: "{주제}-curriculum",
     mode: "bypassPermissions",
     run_in_background: true
   )
   ```

   각 에이전트 프롬프트에 반드시 포함할 내용:
   - 담당 문서 목록과 파일 경로
   - 문서 형식 템플릿 (아래 "문서 형식" 섹션)
   - 참조할 소스코드 경로 (있는 경우)
   - 문서 언어 설정
   - 작성 완료 후 TaskUpdate로 태스크 완료 처리

5. **진행 모니터링**:
   - 주기적으로 TaskList 확인
   - 모든 태스크 완료 시 Phase 4로 진행

### Phase 4. 완료 처리

1. **결과 확인**:
   - 생성된 파일 목록 출력 (Glob으로 확인)
   - 총 문서 수 / 총 라인 수 요약

2. **팀 정리**:
   - 모든 에이전트에 shutdown_request 전송
   - TeamDelete로 팀 리소스 정리

3. **사용자에게 보고**:
   ```
   ## 커리큘럼 생성 완료

   - 주제: {주제}
   - 총 문서: {n}개
   - 경로: {출력_경로}

   ### 생성된 문서
   {파일 목록}
   ```

4. **후속 작업 안내** (AskUserQuestion):
   - header: "다음"
   - question: "추가로 할 작업이 있나요?"
   - options:
     - "Sublime Text로 열기": 전체 문서를 Sublime Text로 열기
     - "Git Push": TIL 저장소에 커밋 & 푸시
     - "완료": 작업 종료

## 문서 형식 템플릿

모든 문서는 다음 형식을 따릅니다:

```markdown
# [제목 (문서 언어)]

[1-2문장 요약]

## 목차
- [1. 핵심 개념 (What)](#1-핵심-개념-what)
- [2. 왜 알아야 하는가 (Why)](#2-왜-알아야-하는가-why)
- [3. 내부 구현 분석 (How)](#3-내부-구현-분석-how)
- [4. 실전 예제](#4-실전-예제)
- [5. 정리](#5-정리)

---

## 1. 핵심 개념 (What)
[개념 정의와 배경]

## 2. 왜 알아야 하는가 (Why)
[실무 동기와 중요성]

## 3. 내부 구현 분석 (How)
[소스코드 워크스루, 다이어그램, 코드 예제]
- mermaid 또는 ASCII 아키텍처 다이어그램 필수
- 소스코드 레퍼런스 (클래스명.메서드명) 포함

## 4. 실전 예제
[Production-ready 코드 예제, 개념당 최소 1-2개]

## 5. 정리
[핵심 요약 — 표 형식 권장]

---
*참고: {기술 스택 버전 정보}*
```

## 에이전트 프롬프트 템플릿

writer 에이전트에게 전달할 프롬프트 구조:

```
You are a curriculum writer. Write {n} detailed technical documents.

## Task
- Use TaskGet with taskId "{id}" to get your full task description
- Use TaskUpdate to set status to "in_progress" and owner to "writer-{n}"

## Document Format
{문서 형식 템플릿 전체}

## Rules
- {문서 언어} explanatory text, English code/class names
- Include mermaid diagrams for architecture visualization
- {소스코드 참조 지침}
- Include production-ready code examples (minimum 1-2 per concept)
- Each document should be comprehensive (200-400 lines of markdown)

## Your Documents
{각 문서별 파일 경로, 제목, 핵심 내용, 참조 소스}

Write each document using the Write tool. After completing all documents, mark your task as completed.
```

## 핵심 규칙

1. **Phase 순서 준수** — 반드시 수집 → 설계 → 승인 → 작성 → 완료 순서
2. **사용자 승인 필수** — 커리큘럼 설계 후 반드시 AskUserQuestion으로 승인
3. **병렬 실행** — 독립적인 문서 그룹은 반드시 병렬 에이전트로 작성
4. **소스코드 기반** — 참조 소스가 있으면 실제 파일을 읽어 정확한 클래스/메서드명 사용
5. **4문서/에이전트** — 에이전트당 최대 4문서 배정 (품질 유지)
6. **파일 열기** — Sublime Text 사용: `open -a "Sublime Text" "{파일_경로}"`

## 사용 예시

```
/curriculum
→ Step 1: [주제] "Spring Data JPA 내부 구현" 입력
→ Step 2: [소스코드] "GitHub Clone" → "https://github.com/spring-projects/spring-data-jpa" 입력
→ Step 3: [경로] "$TIL_ROOT/jpa/" 선택
→ Step 4: [규모] "대형 (20~24문서)" 선택
→ Step 5: [언어] "한국어 (코드는 영어)" 선택
→ 커리큘럼 설계 출력 → "시작" 선택
→ 6개 에이전트 병렬 작성 시작
→ 24개 문서 생성 완료
→ "Git Push" 선택 → commit & push
```
