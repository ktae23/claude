---
name: merge-develop
description: develop 브랜치를 현재 브랜치에 머지합니다. develop 브랜치의 최신 변경사항을 현재 브랜치에 반영하고 싶을 때 사용합니다.
---

# Merge Develop

develop 브랜치의 변경사항을 현재 브랜치에 머지하는 스킬입니다.

## Instructions

다음 단계를 순서대로 실행하세요:

1. 현재 브랜치 이름을 저장합니다
   ```bash
   git branch --show-current
   ```

2. develop 브랜치로 체크아웃합니다
   ```bash
   git checkout develop
   ```

3. develop 브랜치를 pull 받습니다
   ```bash
   git pull
   ```

4. 원래 브랜치로 다시 체크아웃합니다
   ```bash
   git checkout <원래-브랜치-이름>
   ```

5. develop 브랜치를 현재 브랜치에 머지합니다
   ```bash
   git merge develop
   ```

## Notes

- 머지 충돌이 발생하면 사용자에게 알리고 해결 방법을 안내합니다
- 각 단계가 실패하면 즉시 멈추고 사용자에게 알립니다
