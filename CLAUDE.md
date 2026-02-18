# 파일 열기 규칙

파일을 열어서 보여줄 때 항상 Sublime Text를 사용한다.

- 앱 경로: `/Applications/Sublime Text.app`

```bash
open -a "Sublime Text" "{파일_경로}"
```

지원 형식: `.md`, `.markdown`, `.txt`, `.json`, `.yaml`, `.yml`, `.toml`, `.xml`, `.log`, `.ini`, `.cfg`, `.conf`, `.csv`

# claude-code-guide 보정 규칙

claude-code-guide는 틀린 답을 낼 때가 있다. 사용자가 추가 질문을 하면 Claude Code 공식 문서 https://docs.anthropic.com/en/docs/claude-code 에서 md 파일을 curl로 참조해서 답해. 그 후에는 AskUserQuestion으로 퀴즈를 내서 직접 따라하게 안내해.

# npm 보안 가드

## 절대 금지

- `npm publish` 제안/실행 금지 — 사용자가 명시적으로 요청하더라도 `npm audit` 결과를 먼저 보여주고 확인받을 것
- `npm install --unsafe-perm` 실행 금지
- `npm install -g <패키지>` — 검증되지 않은 패키지의 전역 설치 금지. 실행 전 반드시 사용자에게 패키지 신뢰성 확인
- `npm install --no-audit` 실행 금지

## npm install 시 필수 규칙

- **항상 `--ignore-scripts` 옵션을 붙일 것** — `npm install --ignore-scripts <패키지>`
- 스크립트가 필요한 경우 설치 후 `npm rebuild`로 수동 실행
- CI/CD 환경에서는 `npm ci --ignore-scripts` 사용
- 새 패키지 설치 전 `npm audit` 실행을 권장
- 대규모 의존성 추가 전 `npm install --dry-run`으로 미리보기 제안
