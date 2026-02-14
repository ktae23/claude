---
name: md-preview
description: 마크다운 파일을 HTML로 변환하여 브라우저에서 미리보기합니다.
allowed-tools: Bash, Read, Write, Glob, AskUserQuestion
---

# md-preview

마크다운 파일을 HTML로 변환하여 브라우저에서 미리보기합니다.

## 실행 단계

/md-preview 실행 시 다음 단계를 순차적으로 진행합니다.

### Step 0. 작업 선택

**AskUserQuestion 도구**를 사용하여 수행할 작업을 선택받습니다:
- header: "작업"
- question: "수행할 작업을 선택해주세요."
- options:
  - "마크다운 미리보기": 마크다운 파일을 HTML로 변환하여 브라우저에서 열기
  - "임시 파일 정리 (tmp-clear)": /tmp 디렉터리의 모든 *-preview.html 파일 삭제

사용자가 "임시 파일 정리"를 선택하면:
1. `/tmp` 디렉터리에서 `*-preview.html` 패턴의 파일을 검색:
   ```bash
   ls /tmp/*-preview.html 2>/dev/null
   ```

2. 찾은 파일 목록을 사용자에게 보여주고 삭제 확인:
   ```
   다음 파일들을 삭제하시겠습니까?
   - /tmp/file1-preview.html
   - /tmp/file2-preview.html
   ```

3. 확인 후 파일 삭제:
   ```bash
   rm -f /tmp/*-preview.html
   ```

4. 완료 메시지 출력:
   ```
   ✓ {개수}개의 임시 HTML 파일을 삭제했습니다.
   ```

사용자가 "마크다운 미리보기"를 선택하면 Step 1로 진행합니다.

### Step 1. 디렉터리 선택

1. 현재 작업 디렉터리를 기준으로 마크다운 파일이 있는 하위 디렉터리를 검색합니다:
   ```bash
   find . -name "*.md" -type f | sed 's|/[^/]*$||' | sort -u | head -4
   ```

2. **AskUserQuestion 도구**를 사용하여 디렉터리 선택지를 제공합니다:
   - header: "디렉터리"
   - question: "마크다운 파일이 있는 디렉터리를 선택해주세요."
   - options: 검색된 디렉터리들 (최대 4개)
   - 현재 디렉터리(.)도 옵션에 포함
   - 사용자가 "Other"를 선택하면 디렉터리 경로를 직접 입력

### Step 2. 마크다운 파일 선택

1. 선택된 디렉터리에서 모든 .md 파일을 검색합니다 (하위 디렉터리 포함):
   ```bash
   find {선택된_디렉터리} -name "*.md" -type f | sort
   ```

2. **AskUserQuestion 도구**를 사용하여 파일 선택지를 제공합니다:
   - header: "파일"
   - question: "미리보기할 마크다운 파일을 선택해주세요."
   - options: 검색된 모든 .md 파일들 (최대 4개, 파일명만 표시)
   - 사용자가 "Other"를 선택하면 파일 경로를 직접 입력

### Step 3. HTML 변환 및 브라우저에서 열기

1. pandoc을 사용하여 마크다운 파일을 HTML로 변환합니다:
   ```bash
   pandoc "{선택된_파일_경로}" \
     --from gfm \
     --to html5 \
     --standalone \
     --metadata title="{파일명(확장자 제외)}" \
     -o "/tmp/{파일명(확장자 제외)}-preview.html"
   ```

2. 변환된 HTML 파일을 기본 브라우저에서 엽니다:
   ```bash
   open "/tmp/{파일명(확장자 제외)}-preview.html"
   ```

### Step 4. 완료 메시지

```
✓ {파일명}을 HTML로 변환하여 브라우저에서 열었습니다.
```

## 사용 예시

### 마크다운 미리보기

```
/md-preview
→ Step 0: [작업 선택] 마크다운 미리보기 / 임시 파일 정리 → "마크다운 미리보기" 선택
→ Step 1: [디렉터리 선택] ./cache / ./python / ./java / ./auth → "./python" 선택
→ Step 2: [파일 선택] django-프레임워크-사용법.md / fastapi-프레임워크-사용법.md → "django-프레임워크-사용법.md" 선택
→ pandoc으로 HTML 변환 → /tmp/django-프레임워크-사용법-preview.html
→ 브라우저에서 열기
→ ✓ django-프레임워크-사용법.md을 HTML로 변환하여 브라우저에서 열었습니다.
```

### 임시 파일 정리

```
/md-preview
→ Step 0: [작업 선택] 마크다운 미리보기 / 임시 파일 정리 → "임시 파일 정리" 선택
→ 다음 3개의 파일을 찾았습니다:
  - /tmp/cache-strategies-preview.html
  - /tmp/rag-패턴-preview.html
  - /tmp/django-프레임워크-사용법-preview.html
→ [확인] 삭제하시겠습니까? → "예" 선택
→ ✓ 3개의 임시 HTML 파일을 삭제했습니다.
```

## 지원 파일 형식

`.md`, `.markdown`, `.txt`, `.json`, `.yaml`, `.yml`, `.toml`, `.xml`, `.log`, `.ini`, `.cfg`, `.conf`, `.csv`

## 주의사항

- 임시 HTML 파일은 `/tmp` 디렉토리에 생성됩니다
- GitHub Flavored Markdown (GFM)을 지원합니다 (테이블, 체크박스 등)
