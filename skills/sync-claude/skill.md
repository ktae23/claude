---
name: sync-claude
description: 로컬 Claude Code 설정(스킬, 커맨드, 훅, 에이전트, statusline)을 포터블 레포에 동기화합니다.
allowed-tools: Bash, Read, Write, Glob, Grep, Edit, AskUserQuestion
---

# sync-claude

로컬 `~/.claude/` 디렉토리의 스킬, 커맨드, 훅, 에이전트, statusline을 `~/claude` 포터블 레포에 동기화합니다.

## 레포 경로 탐지

Bash로 레포 경로를 탐지합니다:

```bash
# sync-claude 스킬 자신의 위치에서 레포 루트를 역추적
SKILL_PATH=$(find ~/.claude/skills -name 'skill.md' -path '*/sync-claude/*' 2>/dev/null | head -1)
REPO_DIR=$(readlink "$SKILL_PATH" 2>/dev/null | sed 's|/skills/sync-claude/skill.md||' || dirname "$(dirname "$(dirname "$SKILL_PATH")")")
echo "REPO_DIR: $REPO_DIR"
```

심링크를 따라가면 `~/claude`가 됩니다. 심링크가 아닌 경우 디렉토리 구조에서 추론합니다.

## 실행 단계

### Step 1. 로컬 항목 스캔

다음 5개 영역을 스캔하여 레포에 아직 없는 항목을 찾습니다:

```bash
# Skills: 디렉토리 단위
for d in ~/.claude/skills/*/; do
    name=$(basename "$d")
    [ -d "$REPO_DIR/skills/$name" ] || echo "skill: $name"
done

# Commands: 파일 단위
for f in ~/.claude/commands/*.md; do
    [ -f "$f" ] || continue
    name=$(basename "$f")
    [ -f "$REPO_DIR/commands/$name" ] || echo "command: $name"
done

# Hooks: 파일 단위 (hooks/ 디렉토리가 있으면)
if [ -d ~/.claude/hooks ]; then
    for f in ~/.claude/hooks/*; do
        [ -f "$f" ] || continue
        name=$(basename "$f")
        [ -f "$REPO_DIR/hooks/$name" ] || echo "hook: $name"
    done
fi

# Agents: 파일 단위 (agents/ 디렉토리가 있으면)
if [ -d ~/.claude/agents ]; then
    for f in ~/.claude/agents/*.md; do
        [ -f "$f" ] || continue
        name=$(basename "$f")
        [ -f "$REPO_DIR/agents/$name" ] || echo "agent: $name"
    done
fi

# Statusline: 루트 스크립트 파일 (statusline.sh 등)
for f in ~/.claude/statusline*; do
    [ -f "$f" ] || continue
    name=$(basename "$f")
    [ -f "$REPO_DIR/$name" ] || echo "statusline: $name"
done
```

**이미 심링크로 연결된 항목은 "레포에 있는 항목"으로 간주합니다.**

### Step 2. 항목 선택

스캔 결과가 없으면:
- "모든 로컬 항목이 이미 레포에 동기화되어 있습니다." 메시지 출력 후 종료

스캔 결과가 있으면:
- **AskUserQuestion 도구** (multiSelect: true)로 동기화할 항목을 선택받습니다
- header: "동기화"
- question: "레포에 추가할 항목을 선택해주세요."
- 발견된 항목들을 옵션으로 제공 (최대 4개, 나머지는 "Other"로)

### Step 3. 레포에 복사

선택된 각 항목에 대해:

**스킬 (디렉토리):**
```bash
# 생성된 파일 제외하고 복사
rsync -a --exclude='.claude/' --exclude='*.html' ~/.claude/skills/{name}/ $REPO_DIR/skills/{name}/
```

**커맨드/훅/에이전트 (파일):**
```bash
mkdir -p $REPO_DIR/{type}/
cp ~/.claude/{type}/{name} $REPO_DIR/{type}/{name}
```

**Statusline (루트 파일):**
```bash
cp ~/.claude/{name} $REPO_DIR/{name}
```

### Step 4. 이식성 검사

복사된 파일에서 하드코딩된 경로를 검색합니다:

```bash
grep -rn "/Users/" $REPO_DIR/skills/{name}/ 2>/dev/null || true
grep -rn "/home/" $REPO_DIR/skills/{name}/ 2>/dev/null || true
```

하드코딩된 경로가 발견되면:
- 사용자에게 해당 라인을 보여주고 수정할지 **AskUserQuestion**으로 확인
- 수정이 필요하면 Edit 도구로 환경변수나 플레이스홀더로 변경
  - 예: `/Users/buzz/til` → `$TIL_ROOT`

### Step 5. 심링크 전환

원본을 백업하고 레포를 가리키는 심링크로 교체합니다:

**스킬:**
```bash
TIMESTAMP=$(date +%Y%m%d%H%M%S)
mv ~/.claude/skills/{name} ~/.claude/skills/{name}.backup.$TIMESTAMP
ln -s $REPO_DIR/skills/{name} ~/.claude/skills/{name}
```

**커맨드:**
```bash
mv ~/.claude/commands/{name} ~/.claude/commands/{name}.backup.$TIMESTAMP
ln -s $REPO_DIR/commands/{name} ~/.claude/commands/{name}
```

**Statusline:**
```bash
mv ~/.claude/{name} ~/.claude/{name}.backup.$TIMESTAMP
ln -s $REPO_DIR/{name} ~/.claude/{name}
```

### Step 6. Git 커밋 & Push

**AskUserQuestion 도구**로 커밋 메시지를 확인합니다:
- header: "커밋"
- question: "다음 메시지로 커밋하시겠습니까?"
- options:
  - "sync: add {항목 이름들}" (Recommended)
  - "커밋만 (push 안 함)"

```bash
cd $REPO_DIR
git add .
git commit -m "{커밋 메시지}"
git push
```

## 사용 예시

```
/sync-claude
→ 스캔 중...
→ 레포에 없는 항목:
  - skill: my-new-skill
  - command: deploy.md
→ [항목 선택] my-new-skill / deploy.md → 둘 다 선택
→ 레포에 복사 중...
→ 이식성 검사: /Users/buzz/project 발견 (my-new-skill/skill.md:5)
→ [수정 확인] 경로를 플레이스홀더로 변경할까요? → "예"
→ 심링크 전환 완료
→ [커밋] "sync: add my-new-skill, deploy.md" → push 완료
```

## 주의사항

- 이미 레포에 있는 항목은 건너뜁니다 (덮어쓰기 방지)
- 심링크 상태인 항목도 건너뜁니다 (이미 연결됨)
- 백업 파일은 `.backup.TIMESTAMP` 접미사로 생성됩니다
- tarot 등 PC 전용 스킬도 목록에 나타나지만 선택하지 않으면 동기화되지 않습니다
