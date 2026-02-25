---
name: batch-reader-to-sql
description: Batch Job의 ItemReader가 생성하는 Querydsl 쿼리를 실제 MySQL 스키마 기반의 SQL 쿼리로 변환합니다.
---

# Batch Reader to SQL

Batch Job의 ItemReader에서 사용하는 Querydsl 쿼리를 분석하여, 실제 MySQL 8.0에서 실행 가능한 SQL 쿼리로 변환하는 스킬입니다.

## Instructions

다음 단계를 순서대로 실행하세요:

### 1. Reader 상수명 및 Job 파라미터 확인

사용자로부터 다음 형식으로 입력을 받습니다:
- 기본 형식: `<READER_CONSTANT_NAME>`
- 파라미터 포함: `<READER_CONSTANT_NAME> param1=value1 param2=value2`

예시:
- `INDUCE_EXCELLENT_EVALUATOR_RESUME_EVALUATION_READER`
- `INDUCE_EXCELLENT_EVALUATOR_RESUME_EVALUATION_READER targetDate=2025-12-31`

파라미터가 제공되면 이를 파싱하여 key-value 맵으로 저장합니다.

### 2. Reader 메서드 찾기

```bash
# Reader 상수가 사용되는 Job 파일 찾기
grep -r "<READER_CONSTANT_NAME>" batch/src/main/java/com/zaritalk/batch/ --include="*.java"
```

해당 Job 파일을 읽어 `@Bean` 메서드에서 `QuerydslPagingItemReader`를 생성하는 부분을 찾습니다.

### 3. Querydsl 쿼리 코드 및 파라미터 추출

Reader 메서드에서 다음을 추출합니다:

**A. 메서드 파라미터 분석:**
Reader 메서드의 `@Value` 어노테이션을 확인하여 Job 파라미터와 로컬 변수의 관계를 파악합니다.

예시:
```java
public QuerydslPagingItemReader<Lessee> reader(
    @Value("#{ T(java.time.LocalDate).parse(jobParameters['targetDate'])}") final LocalDate targetDate
)
```
이 경우 `jobParameters['targetDate']` → `LocalDate targetDate`로 매핑됩니다.

**B. 메서드 내부 변수 계산 로직 추출:**
Reader 메서드 내부에서 파라미터를 사용하여 계산하는 로컬 변수들을 찾습니다.

예시:
```java
final LocalDateTime startDateTime = LocalDateTime.of(targetDate, LocalTime.MIN);
final LocalDateTime endDateTime = LocalDateTime.of(targetDate, LocalTime.MAX);
```

**C. Querydsl 쿼리 코드 추출:**
`jpaQueryFactory -> jpaQueryFactory.selectFrom(...)` 부분의 쿼리 코드를 추출합니다.

예시:
```java
jpaQueryFactory.selectFrom(lessee)
    .innerJoin(lessee.lesseeDetail, lesseeDetail).fetchJoin()
    .innerJoin(lessee.account, account).fetchJoin()
    .innerJoin(account.accountProfile, accountProfile).fetchJoin()
    .innerJoin(evaluator).on(evaluator.accountPk.eq(lessee.account.pk).and(evaluator.deleted.isFalse()))
    .innerJoin(evaluatorStatistics).on(evaluatorStatistics.evaluator.pk.eq(evaluator.pk))
    .where(evaluatorStatistics.updatedAt.goe(startDateTime).and(evaluatorStatistics.updatedAt.loe(endDateTime)))
    .where(evaluator.blocked.isFalse().and(evaluator.excellent.isTrue()))
```

### 4. Job 파라미터 값 계산 (파라미터가 제공된 경우)

사용자가 파라미터를 제공한 경우, 다음을 수행합니다:

**A. 파라미터 파싱 및 타입 변환:**
- `targetDate=2025-12-31` → `LocalDate.parse("2025-12-31")`
- 날짜 형식 자동 감지 및 변환

**B. 로컬 변수 계산:**
Reader 메서드의 변수 계산 로직을 실행합니다.

예시:
```
targetDate = 2025-12-31
→ startDateTime = 2025-12-31T00:00:00
→ endDateTime = 2025-12-31T23:59:59.999999999
```

**C. 변수-값 매핑 테이블 생성:**
쿼리에서 사용된 모든 변수와 실제 값을 매핑한 테이블을 생성합니다.

| Variable | Value | Type |
|----------|-------|------|
| targetDate | 2025-12-31 | LocalDate |
| startDateTime | 2025-12-31 00:00:00 | LocalDateTime |
| endDateTime | 2025-12-31 23:59:59.999999999 | LocalDateTime |

### 5. 사용된 엔티티 클래스 식별

쿼리에서 사용된 모든 엔티티를 파악합니다:
- static import 문을 확인하여 Q클래스 찾기 (예: `QLessee.lessee`, `QAccount.account`)
- 각 Q클래스에 대응하는 실제 엔티티 클래스 찾기

### 5. 엔티티 필드와 DB 컬럼 매핑 수집

각 엔티티 클래스를 읽어서 다음을 수집합니다:

**테이블명 매핑:**
- `@Entity` 어노테이션 확인
- `@Table(name = "...")` 있으면 그것을 사용, 없으면 클래스명 사용

**컬럼명 매핑:**
- 각 필드의 `@Column(name = "...")` 확인
- `@Column`이 없으면 필드명을 카멜케이스로 사용
- `ColumnConstants`를 사용하는 경우 해당 상수값 확인

**특수 매핑 규칙:**
- `deleted` 필드 → `isDeleted` 컬럼 (ColumnConstants.DELETED)
- `blocked` 필드 → `isBlocked` 컬럼 (ColumnConstants.IS_BLOCKED)
- `excellent` 필드 → `isExcellent` 컬럼 (ColumnConstants.IS_EXCELLENT)
- `admin` 필드 → `isAdmin` 컬럼 (ColumnConstants.IS_ADMIN)
- `pk` 필드 → `PK` 컬럼 (ColumnConstants.PK)
- `accountPk` 필드 → `accountPK` 컬럼 (ColumnConstants.ACCOUNT_PK)
- 기타 PK 관련 필드들도 ColumnConstants 참조

**조인 관계 매핑:**
- `@OneToOne`, `@ManyToOne` 등의 관계 필드 확인
- `@JoinColumn(name = "...")` 으로 FK 컬럼명 확인
- 관계가 `mappedBy`인 경우 반대편 엔티티의 `@JoinColumn` 확인

### 6. MySQL 쿼리 생성

수집한 매핑 정보를 바탕으로 MySQL 쿼리를 생성합니다:

**SELECT 절:**
```sql
SELECT lessee.*
```
또는 필요한 컬럼들을 명시적으로 나열

**FROM 절:**
```sql
FROM <테이블명> <별칭>
```

**JOIN 절:**
- `innerJoin()` → `INNER JOIN`
- `leftJoin()` → `LEFT JOIN`
- `fetchJoin()`은 SQL에서는 표현하지 않음 (JPA의 페치 전략)
- `.on()` 조건을 SQL의 `ON` 절로 변환

조인 조건 변환 규칙:
- `evaluator.accountPk.eq(lessee.account.pk)` → `evaluator.accountPK = account.PK`
- `evaluator.deleted.isFalse()` → `evaluator.isDeleted = false`
- `evaluatorStatistics.evaluator.pk.eq(evaluator.pk)` → `evaluatorStatistics.evaluatorPk = evaluator.PK`

**WHERE 절:**
Querydsl 조건을 SQL 조건으로 변환:
- `.goe(value)` → `>= value`
- `.loe(value)` → `<= value`
- `.eq(value)` → `= value`
- `.ne(value)` → `!= value`
- `.gt(value)` → `> value`
- `.lt(value)` → `< value`
- `.isFalse()` → `= false`
- `.isTrue()` → `= true`
- `.and()` → `AND`
- `.or()` → `OR`

**파라미터 값 치환:**
파라미터가 제공된 경우, 변수를 실제 값으로 치환합니다:
- `startDateTime` → `'2025-12-31 00:00:00'`
- `endDateTime` → `'2025-12-31 23:59:59'`
- LocalDateTime의 마이크로초/나노초 부분은 제거 (MySQL에서 불필요)

파라미터가 없는 경우, 변수를 플레이스홀더로 표시합니다:
- `startDateTime` → `?` (주석: `-- startDateTime`)

**@Where 절 자동 추가:**
`@Where(clause = "isDeleted = false")`가 있는 엔티티는 자동으로 WHERE 조건에 추가됩니다.

### 7. 최종 쿼리 포맷팅

생성된 쿼리를 읽기 쉽게 포맷팅합니다:
- 각 절(SELECT, FROM, JOIN, WHERE)을 새 줄에 배치
- JOIN과 WHERE 조건은 적절히 들여쓰기
- 긴 WHERE 조건은 AND/OR 기준으로 줄바꿈

### 8. 결과 출력

**중요: 사용자에게는 SQL 쿼리만 출력합니다.**

출력 형식:
```sql
[변환된 SQL 쿼리만 출력]
```

다음 내용은 출력하지 않습니다:
- 원본 Querydsl 코드
- Entity-Column 매핑 테이블
- Job 파라미터 계산 과정
- 설명이나 주석

단, SQL 쿼리 자체는 읽기 쉽게 포맷팅하여 출력합니다.

## Important Notes

### 컬럼명 변환 규칙
1. **Boolean 필드**: 대부분 `is` 접두사 추가 (`deleted` → `isDeleted`)
2. **PK 필드**: 대문자 `PK` 사용
3. **FK 필드**: `{entity}PK` 형식 (예: `accountPK`, `lesseePK`)
4. **일반 필드**: 카멜케이스 유지 (예: `phoneNum`, `createdAt`)

### 테이블명 규칙
- 파스칼 케이스 사용 (예: `Account`, `Lessee`, `EvaluatorStatistics`)
- `@Table(name = "...")` 어노테이션이 있으면 해당 값 사용

### 조인 처리
- `fetchJoin()`은 조인 조건에 영향을 주지 않음 (JPA 최적화 힌트)
- 양방향 관계의 경우 FK가 있는 쪽의 조인 조건 사용
- 명시적 `.on()` 조건이 있으면 그것을 우선 사용
- 없으면 관계 매핑 정보에서 FK 컬럼 추출

### AbstractEntity 처리
- `AbstractEntity`를 상속한 엔티티는 자동으로 `isDeleted = false` 조건 추가
- `@Where(clause = "isDeleted = false")` 어노테이션 확인

### 에러 처리
- 엔티티 클래스를 찾을 수 없으면 사용자에게 알림
- 컬럼 매핑을 찾을 수 없으면 필드명을 그대로 사용하고 경고 표시
- 복잡한 서브쿼리나 지원하지 않는 Querydsl 기능이 있으면 사용자에게 수동 변환 필요함을 알림

## Examples

### Example 1: 파라미터 없이 사용

#### Input
```
INDUCE_EXCELLENT_EVALUATOR_RESUME_EVALUATION_READER
```

#### Output
```sql
SELECT lessee.*
FROM Lessee lessee
INNER JOIN LesseeDetail lesseeDetail
  ON lessee.PK = lesseeDetail.lesseePK
INNER JOIN Account account
  ON lessee.masterAccountPk = account.PK
  AND account.isDeleted = false
INNER JOIN AccountProfile accountProfile
  ON account.PK = accountProfile.accountPK
  AND accountProfile.isDeleted = false
INNER JOIN Evaluator evaluator
  ON evaluator.accountPk = account.PK
  AND evaluator.isDeleted = false
INNER JOIN EvaluatorStatistics evaluatorStatistics
  ON evaluatorStatistics.evaluatorPk = evaluator.PK
  AND evaluatorStatistics.isDeleted = false
WHERE evaluatorStatistics.updatedAt >= ?  -- startDateTime
  AND evaluatorStatistics.updatedAt <= ?  -- endDateTime
  AND evaluator.isBlocked = false
  AND evaluator.isExcellent = true
  AND lessee.isDeleted = false
LIMIT ? OFFSET ?  -- pagination
```

### Example 2: 파라미터 포함

#### Input
```
INDUCE_EXCELLENT_EVALUATOR_RESUME_EVALUATION_READER targetDate=2025-12-31
```

#### Job Parameters Calculated
```
targetDate = 2025-12-31
→ startDateTime = 2025-12-31T00:00:00
→ endDateTime = 2025-12-31T23:59:59.999999999
```

#### Output
```sql
SELECT lessee.*
FROM Lessee lessee
INNER JOIN LesseeDetail lesseeDetail
  ON lessee.PK = lesseeDetail.lesseePK
INNER JOIN Account account
  ON lessee.masterAccountPk = account.PK
  AND account.isDeleted = false
INNER JOIN AccountProfile accountProfile
  ON account.PK = accountProfile.accountPK
  AND accountProfile.isDeleted = false
INNER JOIN Evaluator evaluator
  ON evaluator.accountPk = account.PK
  AND evaluator.isDeleted = false
INNER JOIN EvaluatorStatistics evaluatorStatistics
  ON evaluatorStatistics.evaluatorPk = evaluator.PK
  AND evaluatorStatistics.isDeleted = false
WHERE evaluatorStatistics.updatedAt >= '2025-12-31 00:00:00'
  AND evaluatorStatistics.updatedAt <= '2025-12-31 23:59:59'
  AND evaluator.isBlocked = false
  AND evaluator.isExcellent = true
  AND lessee.isDeleted = false
LIMIT ? OFFSET ?;
```