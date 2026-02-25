---
name: review-pr-comments
description: 현재 브랜치로 생성된 PR의 코멘트를 조회하고 유효한 코멘트를 코드에 반영합니다.
---

# Review PR Comments

현재 브랜치로 생성된 PR의 리뷰 코멘트를 조회하고, 유효한 피드백을 코드에 반영하는 스킬입니다.

## 사용법

```bash
# 단독 실행 (1회 실행 후 종료)
/review-pr-comments

# 루프 모드 (ralph-loop와 함께 사용, 10분 간격으로 반복)
/review-pr-comments --loop
```

## Instructions

다음 단계를 순서대로 실행하세요:

### 1. 옵션 확인

인자에 `--loop`가 포함되어 있는지 확인합니다.
- `--loop` 있음: 루프 모드 (상태 파일 사용, ralph-loop와 연동)
- `--loop` 없음: 단독 모드 (상태 파일 무시, 1회 실행)

### 2. 대기 시간 확인 (--loop 모드만)

`--loop` 옵션이 있는 경우에만 `.claude/review-pr-comments-state.json` 파일을 확인합니다.

```bash
cat .claude/review-pr-comments-state.json 2>/dev/null || echo "{}"
```

파일이 존재하고 `wait_until`이 현재 시각보다 미래인 경우:
- 남은 대기 시간을 사용자에게 알리고 즉시 세션을 종료합니다
- ralph-loop가 다시 시작할 때까지 대기합니다

### 3. 현재 브랜치 확인

```bash
git branch --show-current
```

### 4. PR 조회

```bash
gh pr list --head <현재-브랜치-이름> --state open --json number,title,url,state,author
```

만약 PR이 없으면 사용자에게 알리고 종료합니다.

### 5. coderabbit 코멘트 조회

PR의 리뷰 코멘트 중 coderabbit이 작성한 것만 필터링합니다:

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments \
  --jq '.[] | select(.user.login == "coderabbitai[bot]" or .user.login == "coderabbit") | {id: .id, path: .path, line: .original_line, body: .body, user: .user.login, created_at: .created_at}'
```

### 6. Severity 필터링 및 반영 판단

조회된 coderabbit 코멘트에서 다음 패턴을 확인합니다:

**Severity 식별 패턴:**
- **Critical**: `🔴` 또는 `[critical]` 또는 `**Critical**` → **필수 반영**
- **Major**: `🟠` 또는 `[major]` 또는 `**Major**` → **필수 반영**
- **Minor**: `🟡` 또는 `[minor]` 또는 `**Minor**` → **필수 반영**
- **Trivial/Nitpick**: `🔵` 또는 `[trivial]` 또는 `Nitpick` → **판단하에 반영**

**Trivial 반영 기준:**
- 코드 가독성/명확성이 크게 개선되는 경우 → 반영
- 네이밍이 실제 용도와 불일치하여 혼란을 줄 수 있는 경우 → 반영
- 단순 스타일 선호도 차이인 경우 → 건너뜀
- 변경 범위가 너무 넓어 리스크가 있는 경우 → 건너뜀

**제외 대상:**
- 이미 처리된 코멘트 (`processed_comment_ids`에 있는 ID, --loop 모드만)
- `✅ Addressed` 표시가 있는 코멘트

### 7. 코멘트 반영

필터링된 각 코멘트에 대해:

1. 해당 파일을 읽습니다
2. suggestion 블록(` ```suggestion `)이 있으면 해당 코드로 교체합니다
3. suggestion이 없으면 코멘트 내용을 분석하여 적절히 수정합니다
4. 수정 내용을 확인합니다

### 8. Commit & Push

변경사항이 있으면 자동으로 커밋하고 푸시합니다:

```bash
git add -A && git commit -m "fix: apply coderabbit review feedback" && git push
```

### 9. 상태 파일 업데이트 (--loop 모드만)

`--loop` 옵션이 있는 경우에만 `.claude/review-pr-comments-state.json` 파일을 업데이트합니다:

```json
{
  "last_run": "<현재 ISO 시각>",
  "wait_until": "<현재 + 10분 ISO 시각>",
  "processed_comment_ids": [<처리된 코멘트 ID들>],
  "last_pr_number": <PR 번호>
}
```

디렉토리가 없으면 먼저 생성합니다:
```bash
mkdir -p .claude
```

### 10. 완료 처리

**단독 모드 (--loop 없음):**
- 결과를 사용자에게 보고하고 종료합니다

**루프 모드 (--loop 있음):**

새로운 코멘트가 없는 경우:
```
<promise>반영이 필요한 마지막 pr에 coderabbit의 major, minor, critical코멘트가 추가로 달리지 않음</promise>
```

새로운 코멘트가 있는 경우:
- 코멘트를 반영하고 상태 파일을 업데이트한 후 세션을 종료합니다
- ralph-loop가 10분 후 다시 시작하여 새 코멘트를 확인합니다

## 상태 파일 구조 (--loop 모드)

`.claude/review-pr-comments-state.json`:

```json
{
  "last_run": "2026-01-23T10:30:00Z",
  "wait_until": "2026-01-23T10:40:00Z",
  "processed_comment_ids": [12345, 12346],
  "last_pr_number": 42
}
```

## 워크플로우 다이어그램

```
스킬 실행
    │
    ├──(--loop 없음)──→ PR 조회 → 코멘트 반영 → 결과 보고 → 종료
    │
    ▼ (--loop 있음)
대기 시간 확인 ──(대기 중)──→ 즉시 종료 (ralph-loop 재시작)
    │
    ▼ (대기 완료)
PR 조회
    │
    ▼
coderabbit 코멘트 필터링
    │
    ├──(새 코멘트 없음)──→ <promise>출력 → 루프 종료
    │
    ▼ (새 코멘트 있음)
코드 수정 적용 (Critical/Major/Minor 필수, Trivial 판단)
    │
    ▼
git commit & push
    │
    ▼
상태 파일 업데이트 (wait_until = now + 10분)
    │
    ▼
세션 종료 → ralph-loop 재시작 → 반복
```

## Notes

- 코멘트 반영 시 기존 코드 스타일과 컨벤션을 유지합니다
- coderabbit의 suggestion 블록이 있으면 우선적으로 해당 코드를 사용합니다
- Trivial 코멘트는 실질적인 개선이 있는 경우에만 반영합니다
- 충돌이 발생하거나 반영이 어려운 경우 해당 코멘트는 건너뜁니다