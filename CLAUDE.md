# 파일 열기 규칙

파일을 열어서 보여줄 때 항상 Sublime Text를 사용한다.

- 앱 경로: `/Applications/Sublime Text.app`

```bash
open -a "Sublime Text" "{파일_경로}"
```

지원 형식: `.md`, `.markdown`, `.txt`, `.json`, `.yaml`, `.yml`, `.toml`, `.xml`, `.log`, `.ini`, `.cfg`, `.conf`, `.csv`

# claude-code-guide 보정 규칙

claude-code-guide는 틀린 답을 낼 때가 있다. 사용자가 추가 질문을 하면 Claude Code 공식 문서 https://docs.anthropic.com/en/docs/claude-code 에서 md 파일을 curl로 참조해서 답해. 그 후에는 AskUserQuestion으로 퀴즈를 내서 직접 따라하게 안내해.
