---
description: "현재 staging된 변경사항을 분석하여 논리적 단위로 나누어 커밋합니다."
argument-hint: "[--single] (단일 커밋으로 처리)"
---

# Staging된 변경사항 스마트 커밋

## 인자 설명

- `--single` 또는 `-s`: 모든 변경사항을 단일 커밋으로 처리
- 인자가 없으면 변경사항을 분석하여 논리적 단위로 나누어 커밋

## 작업 순서

1. **Staging 상태 확인**

   - `git diff --cached --name-status` 명령으로 staging된 파일 목록 확인
   - staging된 파일이 없으면 사용자에게 알리고 중단
   - 추가(A), 수정(M), 삭제(D), 이름변경(R) 파일 분류

2. **변경 내용 상세 분석**

   - `git diff --cached` 명령으로 전체 staging된 diff 확인
   - 각 파일별 변경사항의 성격 분석:
     - 새로운 기능 추가 (feat)
     - 버그 수정 (fix)
     - 리팩토링 (refactor)
     - 문서 수정 (docs)
     - 테스트 추가/수정 (test)
     - 스타일/포맷팅 (style)
     - 빌드/설정 변경 (chore)

3. **커밋 그룹 분류**

   변경사항을 아래 기준으로 논리적 그룹으로 분류:

   - **파일 위치 기반**: 같은 모듈/디렉토리의 관련 변경사항
   - **변경 유형 기반**: feat, fix, refactor 등 동일한 유형
   - **기능 단위 기반**: 하나의 기능을 완성하는 관련 파일들
   - **의존성 기반**: 서로 의존하는 변경사항은 같은 커밋으로

   분류 우선순위:

   1. 기능 단위로 묶을 수 있으면 먼저 묶음
   2. 같은 모듈 내 관련 변경사항 묶음
   3. 독립적인 변경은 유형별로 분리

4. **커밋 메시지 생성**

   각 그룹에 대해 Conventional Commits 형식의 메시지 생성:

   ```
   <type>(<scope>): <subject>

   <body>
   ```

   - `type`: feat, fix, refactor, docs, test, style, chore 중 선택
   - `scope`: 변경된 모듈/컴포넌트 이름 (선택사항)
   - `subject`: 50자 이내의 간결한 설명 (영문, 소문자로 시작, 마침표 없음)
   - `body`: 상세 설명 (선택사항, 필요시 추가)

5. **커밋 계획 사용자 확인**

   커밋 실행 전 사용자에게 다음을 보여주고 확인:

   ```
   ## 커밋 계획

   ### 커밋 1: <type>(<scope>): <subject>
   포함 파일:
   - path/to/file1.rs (M)
   - path/to/file2.rs (A)

   ### 커밋 2: <type>(<scope>): <subject>
   포함 파일:
   - path/to/file3.rs (M)

   ---
   계속 진행하시겠습니까? (Y/n)
   ```

6. **커밋 실행**

   사용자 확인 후 각 커밋을 순차적으로 실행:

   - 첫 번째 그룹의 파일들을 unstage: `git reset HEAD -- <files>`
   - 해당 그룹의 파일만 다시 stage: `git add <files>`
   - 커밋 실행: `git commit -m "<message>"`
   - 다음 그룹으로 반복

   **주의**: 커밋 순서는 의존성을 고려하여 결정

   - 다른 파일에서 참조하는 파일이 먼저 커밋
   - 테스트 파일은 해당 구현 파일과 함께 커밋

7. **결과 출력**

   ```
   ## 커밋 완료

   ✅ 커밋 1: <hash> <type>(<scope>): <subject>
   ✅ 커밋 2: <hash> <type>(<scope>): <subject>

   총 N개의 커밋이 생성되었습니다.
   ```

## --single 모드

`--single` 또는 `-s` 인자가 주어진 경우:

1. 모든 staging된 변경사항을 분석
2. 전체를 아우르는 하나의 커밋 메시지 생성
3. 사용자 확인 후 단일 커밋 실행: `git commit -m "<message>"`

## 주의사항

- staging된 변경사항이 없으면 `git status`를 보여주고 중단
- 커밋 전에 반드시 사용자 확인을 받음
- 커밋 메시지는 프로젝트의 기존 커밋 히스토리 스타일을 참고
  - `git log --oneline -20` 으로 최근 커밋 스타일 확인
- 너무 작은 단위로 나누지 않음 (최소 의미 있는 단위)
- 너무 큰 단위로 묶지 않음 (리뷰 가능한 크기)
- 충돌 가능성이 있는 변경은 미리 경고
- 실행 중 오류 발생 시 롤백 방법 안내

## 커밋 유형 가이드

| 유형     | 설명             | 예시                           |
| -------- | ---------------- | ------------------------------ |
| feat     | 새로운 기능 추가 | 새 API 엔드포인트, 새 컴포넌트 |
| fix      | 버그 수정        | 오류 수정, 예외 처리           |
| refactor | 리팩토링         | 코드 구조 개선, 성능 최적화    |
| docs     | 문서 수정        | README, 주석, 문서 파일        |
| test     | 테스트           | 테스트 추가/수정               |
| style    | 코드 스타일      | 포맷팅, 세미콜론 등            |
| chore    | 빌드/설정        | 의존성 업데이트, 설정 변경     |

## 예시

### 입력

```
$ /commit
```

### 출력

```
## Staging 분석 결과

총 5개 파일이 staging되어 있습니다:
- M user-control/src/user_control/v2.rs
- A user-control/src/user_control/v2/identity.rs
- A user-control/src/user_control/v2/identity/bot.rs
- M user-control/tests/policy_resolution.rs
- M README.md

## 커밋 계획

### 커밋 1: feat(user-control): add identity module with bot support
포함 파일:
- user-control/src/user_control/v2.rs (M)
- user-control/src/user_control/v2/identity.rs (A)
- user-control/src/user_control/v2/identity/bot.rs (A)

### 커밋 2: test(user-control): update policy resolution tests
포함 파일:
- user-control/tests/policy_resolution.rs (M)

### 커밋 3: docs: update README
포함 파일:
- README.md (M)

---
계속 진행하시겠습니까? (Y/n)
```
