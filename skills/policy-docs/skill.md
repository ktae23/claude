---
name: policy-docs
description: 코드베이스를 분석하여 도메인 정책 문서를 생성하거나 최신화합니다. 기획자용/개발자용/DB스키마 문서를 자동 생성합니다.
---

# Policy Docs

코드베이스를 분석하여 도메인별 정책 문서를 생성하거나 최신화하는 스킬입니다.

## 사용법

```bash
# 새 정책 문서 생성
/policy-docs <도메인명>

# 기존 문서 최신화
/policy-docs <도메인명> --update

# 코드 외 정책 추가 단계 포함
/policy-docs <도메인명> --interactive

# Notion 동기화 포함
/policy-docs <도메인명> --notion

# 복합 사용
/policy-docs <도메인명> --update --interactive --notion
```

**예시:**
```bash
/policy-docs 포인트
/policy-docs 결제 --update
/policy-docs 계약 --interactive
```

**최초 실행 시:**
- 문서 저장 경로를 선택하라는 메시지가 표시됩니다
- 선택한 경로는 `~/.zshrc`에 `POLICY_DOCS_PATH` 환경변수로 저장됩니다
- 이후 실행에서는 저장된 경로가 자동으로 사용됩니다

## Instructions

다음 단계를 순서대로 실행하세요:

### 1. 인자 파싱

사용자 입력에서 다음을 추출합니다:
- **도메인명**: 첫 번째 인자 (필수)
- **--update**: 기존 문서 최신화 모드
- **--interactive**: 코드 외 정책 추가 단계 활성화
- **--notion**: Notion 페이지 동기화 활성화

인자가 없으면 사용자에게 도메인명을 질문합니다.

### 2. 저장 경로 확인

문서 저장 경로를 확인합니다:

```bash
# POLICY_DOCS_PATH 환경변수 확인
echo $POLICY_DOCS_PATH
```

**환경변수가 설정되지 않은 경우 (최초 실행):**

사용자에게 저장 경로를 선택받습니다:

```
정책 문서를 저장할 경로를 선택해주세요:

1. ~/Documents/정책정리 (기본값)
2. 직접 입력

선택:
```

선택한 경로를 `~/.zshrc`에 저장합니다:

```bash
# ~/.zshrc에 추가
echo 'export POLICY_DOCS_PATH="<선택한_경로>"' >> ~/.zshrc

# 현재 세션에 적용
export POLICY_DOCS_PATH="<선택한_경로>"
```

**환경변수가 설정된 경우:**

저장된 경로를 사용합니다. 이후 모든 경로 참조에서 `~/Documents/정책정리` 대신 `$POLICY_DOCS_PATH`를 사용합니다.

### 3. 기존 문서 확인

정책정리 디렉토리에서 해당 도메인 폴더가 있는지 확인합니다:

```bash
ls -la $POLICY_DOCS_PATH/<도메인명>/ 2>/dev/null
```

**문서가 있는 경우:**
- `--update` 옵션이 없으면 사용자에게 최신화 여부를 질문합니다
- 기존 문서를 읽어 현재 버전과 내용을 파악합니다

**문서가 없는 경우:**
- 새 문서 생성 모드로 진행합니다

### 3. 코드베이스 분석

~/callbuslab/zaritalk-api2 에서 해당 도메인 관련 코드를 분석합니다:

**3.1 도메인 패키지 탐색**

```bash
# Core 모듈에서 도메인 패키지 찾기
find ~/callbuslab/zaritalk-api2/core/src/main/java -type d -iname "*<도메인명>*"

# API 모듈에서 도메인 패키지 찾기
find ~/callbuslab/zaritalk-api2/api/src/main/java -type d -iname "*<도메인명>*"

# Batch 모듈에서 도메인 패키지 찾기
find ~/callbuslab/zaritalk-api2/batch/src/main/java -type d -iname "*<도메인명>*"
```

**3.2 핵심 클래스 분석**

다음 순서로 클래스들을 분석합니다:

1. **Entity 클래스**: 도메인 데이터 구조와 DB 스키마 파악
2. **Enum 클래스**: 비즈니스 규칙과 상태값 파악
3. **Facade/Service 클래스**: 비즈니스 로직 흐름 파악
4. **Controller 클래스**: API 엔드포인트 파악
5. **Batch Job 클래스**: 배치 처리 로직 파악
6. **Listener 클래스**: 이벤트/메시지 처리 파악

**3.3 주요 분석 포인트**

각 클래스에서 다음을 추출합니다:

- **정책 관련 상수/설정값**: 금액, 기간, 비율, 제한 등
- **조건 분기 로직**: if/switch 문의 비즈니스 조건
- **Enum 값과 설명**: 상태값, 타입, 카테고리
- **주석**: JavaDoc, 인라인 주석의 비즈니스 설명
- **DB 컬럼 매핑**: @Column, @JoinColumn 등
- **캐시 키 패턴**: 중복 방지, TTL 정책
- **배치 스케줄**: @Scheduled, Job 실행 주기

### 4. 정책 내용 추가 (--interactive 옵션)

`--interactive` 옵션이 있는 경우, 코드 분석 완료 후 사용자에게 질문합니다:

```
코드에서 확인된 정책 외에 추가할 내용이 있나요?

다음과 같은 정보를 추가할 수 있습니다:
- 코드에 명시되지 않은 비즈니스 규칙
- 운영 정책 (고객 문의 대응, 예외 처리 등)
- 기획 의도나 배경 설명
- 향후 변경 예정 사항
- 외부 시스템 연동 정책

추가할 내용을 입력해주세요 (없으면 엔터):
```

사용자 입력이 있으면 해당 내용을 문서에 별도 섹션으로 추가합니다:

```markdown
## 추가 정책 (코드 외)

> 아래 내용은 코드에서 직접 확인할 수 없으며, 기획/운영 정책으로 관리됩니다.

[사용자 입력 내용]
```

### 5. 문서 생성/최신화

도메인 폴더에 3개의 문서를 생성합니다:

**5.1 디렉토리 생성**

```bash
mkdir -p $POLICY_DOCS_PATH/<도메인명>
```

**5.2 기획자용 문서**

파일명: `기획자용 문서 - 사용자 관점의 <도메인명> 정책.md`

**문서 구조:**
```markdown
# 기획자용 문서 - 사용자 관점의 <도메인명> 정책

---

## 1. <도메인> 종류
[Enum, 상태값 기반 - 사용자가 이해할 수 있는 용어로]

## 2. <도메인> 획득/생성 정책
[적립, 생성, 발급 등의 조건과 금액/수량]

## 3. <도메인> 사용/소비 정책
[차감, 사용, 소멸 등의 조건]

## 4. <도메인> 만료/제한 정책
[유효기간, 제한사항]

## 5. 알림/안내 정책
[알림톡, 푸시 등]

---

## 추가 정책 (코드 외)
[--interactive로 추가된 내용, 없으면 섹션 생략]

---

## 변경 이력

| 날짜 | 버전 | 변경 내용 | 작성자 |
| --- | --- | --- | --- |
| <오늘날짜> | <버전> | <변경내용> | @버즈 |
```

**5.3 백엔드 개발자용 문서**

파일명: `백엔드 개발자용 문서 - 기술적 구현 상세.md`

**문서 구조:**
```markdown
# 백엔드 개발자용 문서 - 기술적 구현 상세

---

## 1. 시스템 아키텍처
[모듈 구조, 의존성 다이어그램]

## 2. 핵심 클래스 및 파일 경로
[Facade, Service, Controller, Batch 클래스 표]

## 3. 조회 로직
[캐시 전략, 조회 흐름]

## 4. 처리 로직
[생성/수정/삭제 흐름, 트랜잭션]

## 5. 배치 작업
[Job 목록, 실행 주기, 처리 흐름]

## 6. 캐싱 전략
[캐시 키 형식, TTL, 무효화]

## 7. 메시지 큐 처리
[SQS/Kafka 설정, 리스너]

## 8. 알림 시스템
[알림톡, 슬랙 알림]

## 9. 운영 가이드
[장애 대응, 수동 처리]

---

## 변경 이력

| 날짜 | 버전 | 변경 내용 | 작성자 |
| --- | --- | --- | --- |
| <오늘날짜> | <버전> | <변경내용> | @버즈 |
```

**5.4 DB 스키마 문서**

파일명: `자리톡 <도메인명> DB 스키마 문서.md`

**문서 구조:**
```markdown
# 자리톡 <도메인명> DB 스키마 문서

---

## 1. <테이블명> (설명)

### 역할
[테이블의 목적]

### 컬럼 설명

| 컬럼 | 타입 | 설명 |
| --- | --- | --- |
| pk | bigint (PK) | 고유 식별자 |
| ... | ... | ... |

### 인덱스

| 인덱스명 | 컬럼 | 용도 |
| --- | --- | --- |
| ... | ... | ... |

---

## N. 주요 조회 SQL
[자주 사용되는 쿼리 예시]

---

## N+1. 테이블 관계도
[ASCII 다이어그램]

---

## 변경 이력

| 날짜 | 버전 | 변경 내용 | 작성자 |
| --- | --- | --- | --- |
| <오늘날짜> | <버전> | <변경내용> | @버즈 |
```

### 6. 버전 관리

**신규 생성 시:**
- 버전: `1.0`
- 변경 내용: `최초 작성`

**최신화 시:**
- 기존 버전에서 마이너 버전 증가 (예: `1.0` → `1.1`)
- 변경 내용: 실제 변경된 내용 요약
- 기존 변경 이력 유지하고 새 행 추가

**버전 규칙:**
- 구조 변경, 대규모 수정: 메이저 버전 증가 (`1.x` → `2.0`)
- 내용 추가/수정: 마이너 버전 증가 (`1.0` → `1.1`)

### 7. Notion 동기화 (--notion 옵션)

`--notion` 옵션이 있는 경우, 로컬 문서를 Notion에 동기화합니다.

#### 7.1 환경 설정

**환경변수 확인:**
```bash
# NOTION_API_KEY 환경변수 확인
echo $NOTION_API_KEY
```

**최초 실행 시 (NOTION_API_KEY 미설정):**
사용자에게 Notion API 키를 입력받아 `~/.zshrc`에 저장합니다:

```bash
# ~/.zshrc에 추가
echo 'export NOTION_API_KEY="<입력받은_키>"' >> ~/.zshrc

# 현재 세션에 적용
export NOTION_API_KEY="<입력받은_키>"
```

**환경변수가 있는 경우:**
바로 사용합니다.

**상수 설정:**
```bash
NOTION_PARENT_PAGE_ID="2f6d9f5dcd3080c2b516da6ee134699d"
NOTION_VERSION="2022-06-28"
```

**중요**: API 키는 스킬 파일에 절대 하드코딩하지 않습니다.

#### 7.2 하위 페이지 탐색

Notion API로 '자리톡 백엔드 코드 베이스 정책 문서' 하위 페이지를 조회합니다:

```bash
curl -s -X GET "https://api.notion.com/v1/blocks/${NOTION_PARENT_PAGE_ID}/children?page_size=100" \
  -H "Authorization: Bearer ${NOTION_API_KEY}" \
  -H "Notion-Version: ${NOTION_VERSION}" \
  -H "Content-Type: application/json"
```

응답에서 `child_page` 타입 블록을 필터링하여 기존 페이지 목록을 확보하고, 도메인명과 일치하는 페이지를 찾습니다.

#### 7.3 페이지 생성/업데이트

**페이지가 없는 경우 - 새 하위 페이지 생성:**
```bash
curl -s -X POST "https://api.notion.com/v1/pages" \
  -H "Authorization: Bearer ${NOTION_API_KEY}" \
  -H "Notion-Version: ${NOTION_VERSION}" \
  -H "Content-Type: application/json" \
  -d '{
    "parent": {"page_id": "'${NOTION_PARENT_PAGE_ID}'"},
    "properties": {
      "title": [{"text": {"content": "<도메인명> 정책 문서"}}]
    },
    "children": [/* 마크다운 블록 변환 */]
  }'
```

**페이지가 있는 경우 - 기존 내용 삭제 후 새 내용으로 교체:**
```bash
# 1. 기존 블록 삭제
curl -s -X DELETE "https://api.notion.com/v1/blocks/${BLOCK_ID}" \
  -H "Authorization: Bearer ${NOTION_API_KEY}" \
  -H "Notion-Version: ${NOTION_VERSION}"

# 2. 새 블록 추가
curl -s -X PATCH "https://api.notion.com/v1/blocks/${PAGE_ID}/children" \
  -H "Authorization: Bearer ${NOTION_API_KEY}" \
  -H "Notion-Version: ${NOTION_VERSION}" \
  -H "Content-Type: application/json" \
  -d '{"children": [/* 블록 배열 */]}'
```

#### 7.4 마크다운 → Notion 블록 변환

로컬 마크다운 파일을 Notion 블록 형식으로 변환합니다:

| 마크다운 | Notion 블록 타입 |
|----------|-----------------|
| `# 제목` | `heading_1` |
| `## 제목` | `heading_2` |
| `### 제목` | `heading_3` |
| 본문 텍스트 | `paragraph` |
| `- 항목` | `bulleted_list_item` |
| `1. 항목` | `numbered_list_item` |
| ``` 코드 ``` | `code` |
| `\| 표 \|` | `table` |
| `---` | `divider` |

#### 7.5 동기화 구조

```
Notion: 자리톡 백엔드 코드 베이스 정책 문서 (parent)
├── 포인트/ (child_page)
│   ├── 기획자용 문서 (synced_block or content)
│   ├── 백엔드 개발자용 문서
│   └── DB 스키마 문서
├── 임대장부/ (child_page)
│   └── ...
└── Review/ (child_page)
    └── ...
```

#### 7.6 에러 처리

- **API 키 미설정**: 사용자에게 입력 요청
- **네트워크 오류**: 재시도 (최대 3회)
- **권한 오류**: 페이지 공유 설정 안내 메시지 출력

### 8. 결과 보고

문서 생성/최신화 완료 후 사용자에게 보고합니다:

```
## 정책 문서 생성 완료

**도메인**: <도메인명>
**경로**: $POLICY_DOCS_PATH/<도메인명>/

### 생성된 문서
1. 기획자용 문서 - 사용자 관점의 <도메인명> 정책.md (v<버전>)
2. 백엔드 개발자용 문서 - 기술적 구현 상세.md (v<버전>)
3. 자리톡 <도메인명> DB 스키마 문서.md (v<버전>)

### 분석된 클래스
- Entity: <개수>개
- Service/Facade: <개수>개
- Controller: <개수>개
- Batch Job: <개수>개

### 다음 단계
- 생성된 문서를 검토해주세요
- 누락된 정책이 있다면 `--interactive` 옵션으로 추가할 수 있습니다
- Notion에 동기화하려면 `--notion` 옵션을 사용하세요

### Notion 동기화 (--notion 옵션 사용 시)
- 페이지 URL: <Notion 페이지 링크>
- 동기화된 문서: <개수>개
- 상태: 생성됨 / 업데이트됨
```

## Notes

- 코드에서 명확히 확인되지 않는 정책은 `[확인 필요]` 태그를 붙입니다
- 주석이나 상수명에서 추론한 내용은 `(추정)` 표시를 합니다
- 복잡한 비즈니스 로직은 다이어그램이나 플로우차트로 시각화합니다
- 기존 문서 최신화 시 이전 내용과 diff를 확인하여 변경 사항만 업데이트합니다
- 파일명에 Notion ID 같은 해시가 있으면 제거하고 깔끔한 파일명을 사용합니다

## 도메인 영문명 매핑

코드베이스 탐색 시 다음 매핑을 사용합니다:

| 한글명 | 영문 패키지명 | FE 정 | FE 부 | BE 정 | BE 부 |
| --- | --- | --- | --- | --- | --- |
| 마스터 | master, common | 앨리스 | 글렌 | 레이첼 | 에이든 |
| 임대장부 | rent, ledger, rentreport | 글렌 | 해리, 시드 | 버즈 | 에밀리 |
| 고지서 | bill, notice | 글렌 | 해리, 시드 | 버즈 | 에밀리 |
| 임대차신고 | rentreport, declaration | 글렌 | 해리, 시드 | 버즈 | 에밀리 |
| 자리스테이 | zaristay, stay | 해리 | 시드 | 에밀리 | 에이든 |
| 혜택 | benefit | 글렌 | 디오, 앨리스 | 레이첼 | 버즈 |
| 포인트 | point | 글렌 | 디오, 앨리스 | 레이첼 | 버즈 |
| 콜버스 | callbus | 디오 | 시드 | 버즈 | 기디언 |
| 월세환급 | rentrefund, refund | 디오 | 해리 | 기디언 | 버즈 |
| 자리페이 | zaripay, payment | 디오 | 글렌 | 기디언 | 에이든, 버즈 |
| 중개 | brokerage, agent | 시드 | 해리 | 에이든 | 레이첼 |
| 시세 | price, marketprice | 글렌 | 시드 | 에이든 | 레이첼 |
| 임대인 커뮤니티 | community, landlord | 해리 | 앨리스, 시드 | 버즈 | 기디언 |
| 익명톡 | anonymoustalk, anonymous | 해리 | 글렌 | 버즈 | 기디언 |
| 실거주 리뷰 | review, livingreview | 해리 | 앨리스 | 버즈 | 에밀리 |
| 앱인토스 | appintos, intro | 해리 | 앨리스 | 버즈 | 에밀리 |
| 그로스 | growth, marketing | 시드 | 디오 | 기디언 | 에이든 |
| 어드민 | admin, backoffice | 앨리스 | 디오, 해리 | 기디언 | 에이든 |
| 코어 | core, common, infra | 시드 | 글렌 | 버즈 | 기디언 |
| 앱 | app, mobile | 시드 | 글렌 | - | - |
| 계약 | contract | - | - | - | - |
| 매물 | vacancy | - | - | - | - |
| 알림 | notification, alimtalk | - | - | - | - |
| 정산 | settlement | - | - | - | - |
| 쿠폰 | coupon | - | - | - | - |
| 평가 | evaluation | - | - | - | - |

매핑에 없는 도메인은 사용자에게 영문 패키지명을 질문합니다.

## 도메인별 담당자 요약

정책 문서 작성 시 변경 이력의 작성자 및 검토자 참고용:

### BE 버즈 담당 도메인 (정)
- 임대장부 (고지서, 임대차신고)
- 콜버스
- 임대인 커뮤니티
- 익명톡
- 실거주 리뷰 + 앱인토스
- 코어

### BE 버즈 담당 도메인 (부)
- 혜택 (포인트)
- 월세환급
- 자리페이
