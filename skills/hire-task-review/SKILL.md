---
name: hire-task-review
description: 자리톡 채용 과제 레포지토리를 클론하고 열려있는 PR의 브랜치를 체크아웃하여 자동으로 리뷰를 진행합니다.
---

# Hire Task Review

자리톡 채용 과제 레포지토리를 클론하고 열려있는 PR을 기반으로 자동으로 코드를 리뷰하는 스킬입니다.

**중요: 모든 리뷰 결과와 피드백은 반드시 한글로 작성해야 합니다.**

## Instructions

### 1. 입력 파싱
사용자로부터 다음 형식의 입력을 받습니다:
```
hire-task-review https://github.com/Callbus/aa54b2f2-83ff-4544-a030-6694247b6d21 김규영
```

입력에서 다음 정보를 추출합니다:
- GitHub URL: `https://github.com/Callbus/aa54b2f2-83ff-4544-a030-6694247b6d21`
- 레포지토리: `Callbus/aa54b2f2-83ff-4544-a030-6694247b6d21` (URL에서 추출)
- 디렉토리명: `김규영`

### 2. 레포지토리 클론
```bash
gh repo clone <repository> <directory-name>
```

### 3. 열려있는 PR 확인 및 브랜치 체크아웃
레포지토리에서 열려있는 PR을 확인합니다:
```bash
cd <directory-name>
gh pr list --state open --json number,headRefName,title
```

열려있는 PR이 있으면 해당 브랜치를 체크아웃합니다:
```bash
git checkout <pr-branch-name>
```

PR이 없거나 브랜치가 존재하지 않는 경우 사용자에게 알리고 종료합니다.

### 4. PR 코멘트 조회
열려있는 PR의 코멘트를 조회하여 리뷰 시 참고합니다:
```bash
gh pr view <pr-number> --json comments,reviews
```

**PR 코멘트 활용:**
- 이전 리뷰어들이 남긴 코멘트를 확인합니다
- 지적된 이슈가 해결되었는지 확인합니다
- 리뷰 결과에 PR 코멘트 관련 내용을 포함합니다

### 5. 기본 브랜치와의 차이 확인
먼저 기본 브랜치(main 또는 master)와의 변경사항을 확인합니다:

```bash
# 기본 브랜치 확인
git remote show origin | grep 'HEAD branch' | cut -d' ' -f5
```

```bash
git diff <base-branch>...<pr-branch> --name-only
```

변경된 파일 목록을 확인하고, 각 파일의 상세 변경사항을 확인합니다:
```bash
git diff <base-branch>...<pr-branch>
```

**중요**: 이후 모든 리뷰는 기본 브랜치와의 diff에 나타난 변경사항만을 대상으로 수행합니다.

### 6. 과제 요구사항 확인
다음은 자리톡 단기임대 예약 시스템 과제의 요구사항입니다:

**과제 개요:**
- ReservationController 클래스의 `단기임대 예약 API`가 요구사항에 맞게 동작하도록 코드를 작성 또는 수정
- API: `POST /houses/{houseId}/reservations`

**요구사항:**

1. **예약은 최소 1주일(7일) 이상부터 가능**
   - 체크인 날짜부터 체크아웃 날짜까지의 일수를 기준
   - 예: 2026-01-01 ~ 2026-01-07 (7일) 가능, 2026-01-01 ~ 2026-01-06 (6일) 불가

2. **이미 예약된 날짜는 예약할 수 없음**
   - 예약된 기간: 2026-01-05 ~ 2026-01-10
   - 불가: 2026-01-08 ~ 2026-01-15 (기간이 겹침)
   - 가능: 2026-01-10 ~ 2026-01-17 (체크아웃 날짜부터는 예약 가능)

3. **호스트가 예약 차단을 설정한 기간에는 예약할 수 없음**
   - 차단된 기간: 2026-01-01 ~ 2026-01-03
   - 불가: 2026-01-02 ~ 2026-01-09 (차단 기간과 겹침)
   - 가능: 2026-01-04 ~ 2026-01-11 (차단 종료일 다음날부터 가능)

4. **자신 소유의 숙소는 예약할 수 없음**

5. **예약 완료 시, 알림 메세지를 발송하고, 이력을 남김**
   - 게스트에게 알림 메시지 발송 (System.out.println()으로 대체)
   - 예시: "김자리님의 예약이 완료되었습니다!"
   - NotificationHistory 테이블에 기록

**제공 테이블:**
- Account: 회원 정보
- House: 숙소 정보
- BlockedDate: 호스트가 설정한 예약 차단 기간
- NotificationHistory: 알림 발송 이력

**기술 제약사항:**
- HTTP 헤더 `x-account-id`로 사용자를 식별
- 실제 인증 없이 전달된 값을 신뢰

### 7. 변경된 파일 분석
기본 브랜치와의 diff에서 확인된 변경 파일들을 모두 읽고 분석합니다.

특히 다음 파일들을 중점적으로 확인합니다:
- ReservationController
- Reservation 엔티티
- House 엔티티
- Account 엔티티
- BlockedDate 엔티티
- NotificationHistory 엔티티
- ReservationService
- ReservationRepository
- ReservationEventListener (이벤트 리스너가 있는 경우)
- NotificationService
- 기타 변경된 모든 파일

### 8. 코드 리뷰 수행 - 주요 체크 포인트

각 요구사항별로 구현 상태를 확인하고 피드백을 제공합니다.

**필수 체크리스트:**
- [ ] 1. 최소 1주일(7일) 예약 검증 로직 구현 확인
- [ ] 2. 예약 중복 체크 로직 구현 확인
- [ ] 3. 차단된 날짜 확인 로직 구현 확인
- [ ] 4. 자신 소유 숙소 예약 방지 로직 구현 확인
- [ ] 5. 알림 메시지 발송 (System.out.println) 구현 확인
- [ ] 6. NotificationHistory 저장 로직 구현 확인

**🔴 중요 트랜잭션 체크 포인트:**

만약 코드에 `ReservationEventListener` 또는 `@TransactionalEventListener`를 사용하는 이벤트 리스너가 있다면 **반드시** 다음 사항을 확인해야 합니다:

```java
@RequiredArgsConstructor
@Component
public class ReservationEventListener {
    private final NotificationService notificationService;

    @TransactionalEventListener
    public void onReceive(ReservationCreatedEvent event) {
        // NotificationHistory를 저장하는 로직
        notificationService.notifyReservationConfirmed(account);
    }
}
```

**체크 사항:**
1. `@TransactionalEventListener` 어노테이션 사용 시, 리스너 메서드가 **새로운 트랜잭션에서 실행**되는지 확인
   - `@Transactional(propagation = Propagation.REQUIRES_NEW)` 또는
   - `@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)` + 리스너 내부에서 별도 트랜잭션 시작

2. 만약 새로운 트랜잭션을 열지 않으면:
   - `notificationHistoryCommandService.save(notificationHistory)` 같은 저장 로직이 **커밋되지 않음**
   - 부모 트랜잭션이 이미 커밋된 후 이벤트가 발생하므로, 리스너에서 DB 변경사항이 반영되지 않음

3. **해결 방법 (반드시 리뷰에 포함):**
   ```java
   @TransactionalEventListener
   @Transactional(propagation = Propagation.REQUIRES_NEW)
   public void onReceive(ReservationCreatedEvent event) {
       // 새로운 트랜잭션에서 실행됨 - 정상적으로 커밋됨
   }
   ```

**이 문제가 발견되면 반드시 한글로 상세히 설명하고 개선 방법을 제시해야 합니다.**

### 9. 날짜 로직 검증
기본 브랜치와의 diff에서 변경된 날짜 비교 로직을 중점적으로 검토합니다:
- 날짜 겹침 검증 로직이 정확한지
- 경계값 처리가 올바른지 (체크아웃 날짜부터 예약 가능)
- LocalDate 사용이 적절한지

### 10. 아키텍처 및 설계 검토
기본 브랜치와의 diff를 기반으로:
- 비즈니스 로직이 적절한 계층에 위치하는지
- Controller, Service, Domain의 책임이 명확히 분리되어 있는지
- 엔티티 연관관계가 적절한지
- 이벤트 기반 아키텍처를 사용했다면 올바르게 구현되었는지

### 11. 테스트 코드 확인
변경된 파일 중 테스트 파일이 있는지 확인:
```bash
git diff <base-branch>...<pr-branch> --name-only | grep -i test
```

각 요구사항이 테스트되고 있는지 검토합니다.

### 12. 빌드 및 테스트 실행
프로젝트가 정상적으로 빌드되고 테스트를 통과하는지 확인합니다:
```bash
./gradlew clean test
```
또는
```bash
./mvnw clean test
```

테스트 실패가 있다면 원인을 분석하여 리뷰에 포함합니다.

### 13. 리뷰 결과 정리 (한글로 작성)
다음 형식으로 리뷰 결과를 **반드시 한글로** 정리하여 사용자에게 제공합니다:

#### 📌 PR 정보
- [PR 번호, 제목, 브랜치명]

#### 💬 PR 코멘트 요약
- [기존 PR에 달린 코멘트 요약]
- [지적된 이슈와 해결 여부]

#### 📝 변경 사항 요약
- [기본 브랜치와 비교하여 어떤 파일들이 변경되었는지 요약]

#### 📋 구현 완료 항목
- [구현이 완료된 요구사항을 한글로 나열]

#### ⚠️ 미구현 또는 개선 필요 항목
- [미구현 요구사항 및 개선사항을 한글로 상세히 설명]
- **특히 트랜잭션 관련 이슈가 발견되면 최우선으로 언급**

#### 🔴 트랜잭션 이슈 (발견 시)
- [@TransactionalEventListener 사용 시 새로운 트랜잭션 미생성 문제]
- [NotificationHistory 저장 커밋 안되는 문제]
- [해결 방법 제시]

#### 💡 코드 품질 피드백
- [코드 품질, 구조, 네이밍, 설계 등에 대한 피드백을 한글로 작성]

#### 🧪 테스트 커버리지
- [테스트 코드 현황 및 추가로 필요한 테스트를 한글로 설명]

#### 🎯 전체 평가 및 제안사항
- [전반적인 코드 품질 평가 및 개선 제안을 한글로 작성]

## Notes
- **모든 리뷰 내용은 반드시 한글로 작성합니다**
- **기본 브랜치와의 diff에 나타난 변경사항만을 대상으로 리뷰합니다**
- **PR 코멘트를 확인하여 이전 피드백 반영 여부를 검토합니다**
- 코드 리뷰 시 Spring Boot 및 JPA 베스트 프랙티스를 고려합니다
- 비즈니스 로직이 적절한 계층(Controller/Service/Domain)에 위치하는지 확인합니다
- 예외 처리 및 에러 메시지가 적절한지 검토합니다
- **@TransactionalEventListener 사용 시 트랜잭션 전파 설정을 반드시 확인합니다**
- 날짜 비교 로직이 정확한지 검증합니다
- 엔티티 연관관계가 적절하게 설정되어 있는지 확인합니다
- 이벤트 기반 아키텍처 사용 시 이벤트 발행/구독이 올바르게 구현되었는지 확인합니다
