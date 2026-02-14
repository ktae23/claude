# Plugins

플러그인은 심링크로 관리할 수 없어 각 PC에서 수동으로 설치해야 합니다.

## claude-mem (MCP Plugin)

크로스 세션 메모리를 제공하는 MCP 플러그인입니다.

### 설치

```bash
claude mcp add claude-mem -- npx -y @anthropic-ai/claude-mem-mcp@latest
```

### 설정 확인

`settings.json`의 `enabledPlugins`에 이미 등록되어 있습니다:

```json
{
  "enabledPlugins": {
    "claude-mem@thedotmack": true
  }
}
```

install.sh로 settings.json을 심링크하면 플러그인 활성화 설정이 자동으로 적용됩니다.
MCP 서버 등록만 수동으로 해주면 됩니다.
