# .agents

> AI 코딩 에이전트(Roo Code, Claude Code)의 설정, 커맨드, 스킬, 규칙을 **단일 저장소**에서 중앙 관리하는 dotfiles 스타일 설정 프레임워크

## 왜 필요한가?

Roo Code와 Claude Code는 각각 `~/.roo/`, `~/.claude/` 등 서로 다른 경로에 설정을 저장합니다.
에이전트가 늘어날수록 **동일한 커맨드·스킬·규칙을 여러 곳에 복사**해야 하는 문제가 생깁니다.

`.agents`는 심볼릭 링크를 통해 하나의 Git 저장소에서 모든 에이전트 설정을 관리합니다.

```
~/.agents (이 저장소)
  ├── commands/     ─── symlink ──→  ~/.claude/commands/
  │                 ─── symlink ──→  ~/.roo/commands/
  ├── skills/       ─── symlink ──→  ~/.claude/skills/
  │                 ─── symlink ──→  ~/.roo/skills/
  ├── .claude/      ─── symlink ──→  ~/.claude/settings.json
  └── .roo/rules/   ─── symlink ──→  ~/.roo/rules/
```

## 빠른 시작

### 요구 사항

- macOS / Linux
- Git
- Bash 4+

### 설치

```bash
# 1. 저장소 클론
git clone <repo-url> ~/.agents

# 2. 심볼릭 링크 설정
~/.agents/setup.sh
```

`setup.sh`는 기존 파일이 있으면 `.backups/` 디렉토리에 타임스탬프와 함께 자동 백업한 뒤 심볼릭 링크를 생성합니다. 이미 올바른 링크가 존재하면 스킵합니다.

### 설정 확인

```bash
ls -la ~/.claude/commands   # → ~/.agents/commands
ls -la ~/.roo/commands      # → ~/.agents/commands
ls -la ~/.roo/skills        # → ~/.agents/skills
```

## 프로젝트 구조

```
.agents/
├── setup.sh                          # 심볼릭 링크 설정 스크립트
├── commands/                         # 슬래시 커맨드 (Roo Code · Claude Code 공유)
│   ├── commit.md                     #   /commit - 스마트 커밋 분할
│   ├── pr.md                         #   /pr - GitHub PR 자동 생성
│   ├── review.md                     #   /review - 코드 리뷰 수행
│   ├── summary.md                    #   /summary - 변경사항 요약
│   ├── rearrange.md                  #   /rearrange - 커밋 재정렬
│   └── pdftomd.md                    #   /pdftomd - PDF→Markdown 변환
├── skills/                           # 에이전트 스킬
│   └── evaluate-instructions/        #   에이전트 설정 파일 품질 평가
│       ├── SKILL.md                  #     스킬 정의 및 평가 루브릭
│       └── IMPROVE.md                #     자기 개선 가이드
├── .claude/                          # Claude Code 설정
│   ├── settings.json                 #   MCP 서버, 플러그인, 권한 설정
│   └── settings.local.json           #   로컬 전용 권한 설정
├── .roo/                             # Roo Code 설정
│   └── rules/
│       └── rules.md                  #   글로벌 규칙 (pnpm 강제 등)
├── .backups/                         # setup.sh에 의한 자동 백업 (gitignored)
└── .gitignore
```

## 커맨드

`commands/` 디렉토리의 마크다운 파일은 에이전트 내에서 `/명령어` 형태로 호출됩니다.

| 커맨드       | 설명                                                    | 사용법                              |
| ------------ | ------------------------------------------------------- | ----------------------------------- |
| `/commit`    | staging된 변경사항을 분석하여 논리적 단위로 나누어 커밋 | `/commit` 또는 `/commit --single`   |
| `/pr`        | 변경사항을 요약하고 GitHub PR 자동 생성                 | `/pr` 또는 `/pr dev`                |
| `/review`    | 현재 브랜치의 변경사항을 다각도로 코드 리뷰             | `/review`                           |
| `/summary`   | 브랜치 변경사항 분석 및 요약 생성                       | `/summary` 또는 `/summary dev`      |
| `/rearrange` | 커밋들을 리뷰하기 쉽게 재정렬·분할·병합                 | `/rearrange` 또는 `/rearrange main` |
| `/pdftomd`   | PDF 파일을 구조를 유지하며 마크다운으로 변환            | `/pdftomd <파일경로>`               |

## 스킬

`skills/` 디렉토리에는 특정 조건에서 자동 활성화되는 에이전트 스킬이 포함됩니다.

### evaluate-instructions

에이전트 설정 파일(AGENTS.md, CLAUDE.md, .cursorrules 등)의 품질을 **ArXiv 논문 20편** 기반의 8개 카테고리로 정량 평가합니다.

- **평가 카테고리**: 구조, 명확성, 컨텍스트, 추론 유도, 피드백, 안전/제약, 에이전틱, 컨텍스트 진화
- **출력**: 0-100점 종합 점수 + 카테고리별 상세 보고서 + 개선 권고
- **자기 개선**: 평가 결과를 기반으로 설정 파일을 자동 개선하는 IMPROVE 워크플로우 포함

## 규칙

`.roo/rules/rules.md`에 정의된 글로벌 규칙이 모든 에이전트 세션에 적용됩니다.

현재 설정된 규칙:

- **패키지 매니저**: `npm`, `yarn` 대신 항상 `pnpm` 사용 (`npx` → `pnpx`)

## setup.sh 동작 방식

```bash
~/.agents/setup.sh
```

1. **백업**: 기존 파일/심볼릭 링크가 있으면 `.backups/<타임스탬프>/` 에 복사
2. **검증**: 이미 올바른 심볼릭 링크면 스킵
3. **생성**: 부모 디렉토리를 자동 생성하고 심볼릭 링크 설정

생성되는 심볼릭 링크:

| 링크 경로                 | 대상                              |
| ------------------------- | --------------------------------- |
| `~/.claude/commands`      | `~/.agents/commands`              |
| `~/.roo/commands`         | `~/.agents/commands`              |
| `~/.roo/skills`           | `~/.agents/skills`                |
| `~/.claude/skills`        | `~/.agents/skills`                |
| `~/.claude/settings.json` | `~/.agents/.claude/settings.json` |
| `~/.roo/rules`            | `~/.agents/.roo/rules`            |

## 커스터마이징

### 커맨드 추가

`commands/` 디렉토리에 마크다운 파일을 추가하면 양쪽 에이전트에서 바로 사용 가능합니다:

```markdown
---
description: "커맨드 설명"
argument-hint: "[인자] (설명)"
---

# 커맨드 제목

커맨드 지시사항...
```

### 스킬 추가

`skills/<스킬명>/SKILL.md` 파일을 생성합니다:

```markdown
---
name: 스킬명
description: "스킬 설명 및 트리거 조건"
---

# 스킬 지시사항

...
```

### 규칙 추가

`.roo/rules/rules.md` 파일을 편집하여 글로벌 규칙을 추가합니다.

## 보안

- `.claude/settings.json`은 MCP 서버 토큰 등 민감 정보를 포함하므로 **`.gitignore`로 추적 제외** 되어 있습니다.
- `.backups/` 디렉토리도 gitignore 처리되어 있습니다.
- 저장소를 공개할 경우 `.claude/settings.json`에 민감 정보가 포함되지 않았는지 반드시 확인하세요.

## 라이선스

개인 dotfiles 저장소입니다.
