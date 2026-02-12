# Project: .agents

AI 코딩 에이전트(Roo Code, Claude Code)의 설정·커맨드·스킬·규칙을 심볼릭 링크로 중앙 관리하는 dotfiles 저장소.

## 기술 스택

- Shell (Bash) — 설정 자동화 스크립트
- Markdown — 커맨드, 스킬, 규칙 정의
- Symlink 기반 설정 배포

## 핵심 규칙

### Do

- `npm`, `yarn` 대신 항상 `pnpm`을 사용하라 (`npx` → `pnpx`). 프로젝트 전체 일관성을 위함.
- 커맨드 파일은 YAML frontmatter(`description`, `argument-hint`)를 포함하라. 에이전트가 커맨드 목록을 표시할 때 사용됨.
- 스킬 파일은 `skills/<스킬명>/SKILL.md` 경로를 따르라. Roo Code와 Claude Code 양쪽에서 인식하는 구조.
- `.claude/settings.json`은 민감 정보를 포함하므로 `.gitignore`에 반드시 유지하라.
- `setup.sh` 수정 시 기존 심볼릭 링크 구조와의 호환성을 유지하라.

### Don't

- `.backups/` 디렉토리의 내용을 Git에 커밋하지 마라.
- 커맨드·스킬 파일을 `~/.claude/`나 `~/.roo/`에 직접 작성하지 마라. 심볼릭 링크가 깨짐.

## 프로젝트 구조

```
.agents/
├── setup.sh                      # 심볼릭 링크 설정 (백업 → 검증 → 생성)
├── commands/                     # 슬래시 커맨드 (/commit, /pr, /review 등)
├── skills/                       # 에이전트 스킬 (evaluate-instructions 등)
├── .claude/                      # Claude Code 설정 (settings.json)
├── .roo/rules/                   # Roo Code 글로벌 규칙
├── .backups/                     # 자동 백업 (gitignored)
├── README.md                     # 프로젝트 문서
└── AGENTS.md                     # 에이전트 지시 파일 (이 파일)
```

## 안전 경계

### 자율 수행

- 파일 읽기, 커맨드·스킬·규칙 파일 편집
- `setup.sh` 실행

### 확인 필요

- `.claude/settings.json` 내 MCP 서버·토큰 변경
- `setup.sh`의 심볼릭 링크 대상 경로 변경
- `.gitignore` 수정

## README 최신 상태 유지

이 저장소에 구조적 변경(커맨드 추가/삭제, 스킬 추가/삭제, 규칙 변경, setup.sh 링크 대상 변경 등)이 발생하면 **반드시 `README.md`를 해당 변경사항에 맞게 업데이트**하라.

업데이트 대상 섹션:

- **프로젝트 구조**: 파일·디렉토리가 추가/삭제된 경우
- **커맨드 테이블**: `commands/`에 파일이 추가/삭제/수정된 경우
- **스킬 섹션**: `skills/`에 스킬이 추가/삭제된 경우
- **규칙 섹션**: `.roo/rules/rules.md`가 변경된 경우
- **setup.sh 동작 방식**: 심볼릭 링크 대상이 변경된 경우

README 업데이트를 빠뜨리면 문서와 실제 동작이 불일치하여 사용자 혼란을 유발한다.
