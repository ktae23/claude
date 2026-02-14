# Claude Code Portable Config

여러 PC에서 동일한 Claude Code 환경을 재현하기 위한 포터블 설정 레포지토리.

## Quick Start

### 새 PC에서 설치

```bash
git clone https://github.com/ktae23/claude.git ~/claude
cd ~/claude && bash install.sh
```

install.sh가 안내하는 대로 코어 설정과 스킬/커맨드를 선택적으로 설치합니다.

### 제거

```bash
bash ~/claude/uninstall.sh
```

이 레포를 가리키는 심링크만 제거합니다. 다른 파일에는 영향 없습니다.

## 구조

```
~/claude/
├── CLAUDE.md              # 글로벌 지시사항
├── settings.json          # 환경 설정
├── install.sh             # 설치 스크립트
├── uninstall.sh           # 제거 스크립트
├── skills/
│   ├── sync-claude/       # 로컬→레포 동기화 스킬
│   ├── til/               # TIL 학습 기록 매니저
│   └── til-viewer/        # TIL 인터랙티브 웹 뷰어
├── commands/
│   └── md-preview.md      # 마크다운 미리보기
└── plugins/
    └── README.md          # 플러그인 수동 설치 가이드
```

## 워크플로우

### 심링크 방식

install.sh는 `~/.claude/` 안의 파일을 이 레포의 파일로 심링크합니다.
어디서 수정해도 양방향으로 즉시 반영됩니다.

- **스킬**: 디렉토리 심링크 (하위구조 유지)
- **커맨드**: 파일 심링크 (로컬 전용 커맨드와 공존)
- **코어 설정**: 파일 심링크

### 새 스킬/커맨드 추가

Claude Code에서 `/sync-claude`를 실행하면:

1. 로컬 `~/.claude/`에만 있는 항목을 자동 감지
2. 원하는 항목을 선택하여 레포에 추가
3. 이식성 검사 (하드코딩 경로 → 플레이스홀더)
4. 심링크 전환 + git commit & push

### 다른 PC에서 받기

```bash
cd ~/claude && git pull
bash install.sh  # 새 항목만 추가 설치 (멱등성)
```

## 주의사항

- **플러그인**은 심링크 불가 → `plugins/README.md` 참고하여 수동 설치
- **PC 전용 스킬** (tarot 등)은 `/sync-claude`로 동기화하지 않으면 로컬에만 유지
- `til` 스킬의 저장소 경로는 `$TIL_ROOT`로 설정되어 있어 새 PC 첫 실행 시 자동으로 경로 설정 유도
