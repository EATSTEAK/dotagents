# .agents

> AI 코딩 에이전트(Roo Code, Claude Code, OpenCode)의 설정, 스킬, 규칙을 **단일 저장소**에서 중앙 관리하는 dotfiles 스타일 설정 프레임워크

## 왜 필요한가?

Roo Code, Claude Code, OpenCode는 각각 `~/.roo/`, `~/.claude/`, `~/.config/opencode/` 등 서로 다른 경로에 설정을 저장합니다.
에이전트가 늘어날수록 **동일한 스킬·규칙을 여러 곳에 복사**해야 하는 문제가 생깁니다.

`.agents`는 심볼릭 링크를 통해 하나의 Git 저장소에서 모든 에이전트 설정을 관리합니다.

```
~/.agents (이 저장소)
  ├── skills/       ─── symlink ──→  ~/.claude/skills/
  │                 ─── symlink ──→  ~/.roo/skills/
  │                 ─── symlink ──→  ~/.config/opencode/skills/
  ├── .claude/      ─── symlink ──→  ~/.claude/settings.json
  ├── .opencode/    ─── symlink ──→  ~/.config/opencode/opencode.json
  ├── .roo/rules/   ─── symlink ──→  ~/.roo/rules/
  └── hermes/       ─── symlink ──→  ~/.hermes/config.yaml
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
ls -la ~/.roo/skills        # → ~/.agents/skills
ls -la ~/.config/opencode/skills   # → ~/.agents/skills
ls -la ~/.hermes/config.yaml # → ~/.agents/hermes/config.yaml
```

## 프로젝트 구조

```
.agents/
├── setup.sh                          # 심볼릭 링크 설정 스크립트
├── skills/                           # 에이전트 스킬
│   ├── commit/                       #   staged 변경사항 스마트 커밋
│   ├── pr/                           #   GitHub PR 생성
│   ├── review/                       #   코드 리뷰 수행
│   ├── summary/                      #   변경사항 요약
│   ├── rearrange/                    #   커밋 재정렬
│   ├── pdftomd/                      #   PDF→Markdown 변환
│   └── evaluate-instructions/        #   에이전트 설정 파일 품질 평가
├── .claude/                          # Claude Code 설정
│   ├── settings.json                 #   MCP 서버, 플러그인, 권한 설정
│   └── settings.local.json           #   로컬 전용 권한 설정
├── .opencode/                        # OpenCode 설정
│   └── opencode.json                 #   MCP 서버, 스킬 경로 설정
├── .roo/                             # Roo Code 설정
│   └── rules/
│       └── rules.md                  #   글로벌 규칙 (pnpm 강제 등)
├── hermes/                           # Hermes Agent 설정
│   └── config.yaml                   #   ~/.hermes/config.yaml 원본
├── .backups/                         # setup.sh에 의한 자동 백업 (gitignored)
└── .gitignore
```

## 스킬

`skills/` 디렉토리에는 특정 조건에서 자동 활성화되는 에이전트 스킬이 포함됩니다. OpenCode는 `~/.config/opencode/skills/` 링크와 `~/.agents/skills` 경로 설정을 통해 같은 스킬을 읽습니다.

커맨드로 관리하던 워크플로우는 `pnpx skills` CLI로 설치되는 스킬로 전환되었습니다.

| 스킬        | 설명                                                    |
| ----------- | ------------------------------------------------------- |
| `commit`    | staged 변경사항을 분석하여 논리적 단위로 나누어 커밋    |
| `pr`        | 변경사항을 요약하고 GitHub PR 생성                      |
| `review`    | 브랜치 diff, staged diff, 특정 파일 코드 리뷰           |
| `summary`   | 브랜치 변경사항 분석 및 요약 생성                       |
| `rearrange` | 커밋들을 리뷰하기 쉽게 재정렬·분할·병합                 |
| `pdftomd`   | PDF 파일을 구조를 유지하며 마크다운으로 변환            |

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

| 링크 경로                              | 대상                                          |
| -------------------------------------- | --------------------------------------------- |
| `~/.roo/skills`                        | `~/.agents/skills`                            |
| `~/.claude/skills`                     | `~/.agents/skills`                            |
| `~/.config/opencode/skills`            | `~/.agents/skills`                            |
| `~/.config/opencode/opencode.json`     | `~/.agents/.opencode/opencode.json`           |
| `~/.claude/settings.json`              | `~/.agents/.claude/settings.json`             |
| `~/.claude/statusline-command.sh`      | `~/.agents/.claude/statusline-command.sh`     |
| `~/.roo/rules`                         | `~/.agents/.roo/rules`                        |
| `~/.hermes/config.yaml`                | `~/.agents/hermes/config.yaml`                |

## 커스터마이징

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
