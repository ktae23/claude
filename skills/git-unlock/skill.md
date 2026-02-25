---
name: git-unlock
description: git index.lock 파일을 삭제하여 git 프로세스 잠금을 해제합니다.
---

# Git Unlock

git index.lock 파일을 삭제하여 "Another git process seems to be running" 오류를 해결합니다.

## Instructions

현재 디렉토리의 .git/index.lock 파일을 삭제합니다:

```bash
rm -f .git/index.lock
```

## Notes

- 다른 git 프로세스가 실제로 실행 중인 경우 해당 프로세스가 완료될 때까지 기다리는 것이 좋습니다
- 이 명령은 git 프로세스가 비정상 종료되어 lock 파일이 남아있을 때 사용합니다