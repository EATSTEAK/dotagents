#!/usr/bin/env bash
set -euo pipefail

# .mcp.json 기반으로 Claude Code user-scope MCP 서버를 동기화하는 스크립트
# 사용법: ./scripts/reconcile-mcp.sh [--dry-run] [--scope local|user] [--mcp-json <path>]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 기본값
DRY_RUN=false
SCOPE="user"
MCP_JSON="${PROJECT_ROOT}/.mcp.json"

# 인자 파싱
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --scope)
      SCOPE="$2"
      shift 2
      ;;
    --mcp-json)
      MCP_JSON="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--dry-run] [--scope local|user] [--mcp-json <path>]"
      echo ""
      echo "Options:"
      echo "  --dry-run          변경사항만 출력하고 실행하지 않음"
      echo "  --scope            MCP 서버 scope (default: user)"
      echo "  --mcp-json         .mcp.json 파일 경로 (default: <project-root>/.mcp.json)"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "$MCP_JSON" ]]; then
  echo "Error: $MCP_JSON not found" >&2
  exit 1
fi

if ! command -v claude &>/dev/null; then
  echo "Error: claude CLI not found" >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "Error: jq not found (brew install jq)" >&2
  exit 1
fi

echo "=== MCP Reconcile ==="
echo "Source: $MCP_JSON"
echo "Scope:  $SCOPE"
echo "Dry-run: $DRY_RUN"
echo ""

# .mcp.json에서 서버 이름 목록 추출
DESIRED_SERVERS=$(jq -r '.mcpServers | keys[]' "$MCP_JSON")

# 현재 등록된 서버 목록 가져오기 (~/.claude.json에서 직접 읽음)
CLAUDE_JSON="$HOME/.claude.json"
if [[ -f "$CLAUDE_JSON" ]]; then
  if [[ "$SCOPE" == "user" ]]; then
    CURRENT_SERVERS=$(jq -r '.mcpServers // {} | keys[]' "$CLAUDE_JSON" 2>/dev/null || true)
  else
    # local scope는 프로젝트별로 저장됨
    CURRENT_SERVERS=$(jq -r --arg path "$PROJECT_ROOT" '.projects[$path].mcpServers // {} | keys[]' "$CLAUDE_JSON" 2>/dev/null || true)
  fi
else
  CURRENT_SERVERS=""
fi

# 추가할 서버 계산
TO_ADD=()
TO_UPDATE=()
TO_REMOVE=()

for server in $DESIRED_SERVERS; do
  DESIRED_CONFIG=$(jq -c ".mcpServers[\"$server\"]" "$MCP_JSON")

  if echo "$CURRENT_SERVERS" | grep -qx "$server"; then
    # 이미 존재 — 설정이 다른지 비교
    if [[ "$SCOPE" == "user" ]]; then
      CURRENT_CONFIG=$(jq -c ".mcpServers[\"$server\"]" "$CLAUDE_JSON" 2>/dev/null || echo "{}")
    else
      CURRENT_CONFIG=$(jq -c --arg path "$PROJECT_ROOT" ".projects[\$path].mcpServers[\"$server\"]" "$CLAUDE_JSON" 2>/dev/null || echo "{}")
    fi

    # 비교를 위해 정규화 (alwaysAllow 등 Claude Code가 추가하는 필드 제외)
    DESIRED_NORM=$(echo "$DESIRED_CONFIG" | jq -cS 'del(.alwaysAllow, .disabled)')
    CURRENT_NORM=$(echo "$CURRENT_CONFIG" | jq -cS 'del(.alwaysAllow, .disabled)')

    if [[ "$DESIRED_NORM" != "$CURRENT_NORM" ]]; then
      TO_UPDATE+=("$server")
    fi
  else
    TO_ADD+=("$server")
  fi
done

# 제거할 서버 계산 (.mcp.json에 없는 서버)
for server in $CURRENT_SERVERS; do
  if ! echo "$DESIRED_SERVERS" | grep -qx "$server"; then
    TO_REMOVE+=("$server")
  fi
done

# 결과 출력
echo "--- Changes ---"
[[ ${#TO_ADD[@]} -eq 0 ]] && [[ ${#TO_UPDATE[@]} -eq 0 ]] && [[ ${#TO_REMOVE[@]} -eq 0 ]] && {
  echo "No changes needed. Already in sync."
  exit 0
}

for s in "${TO_ADD[@]+"${TO_ADD[@]}"}"; do
  [[ -n "$s" ]] && echo "  + ADD:    $s"
done
for s in "${TO_UPDATE[@]+"${TO_UPDATE[@]}"}"; do
  [[ -n "$s" ]] && echo "  ~ UPDATE: $s"
done
for s in "${TO_REMOVE[@]+"${TO_REMOVE[@]}"}"; do
  [[ -n "$s" ]] && echo "  - REMOVE: $s"
done
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
  echo "(dry-run mode — no changes applied)"
  exit 0
fi

# 실행
run_cmd() {
  echo "  > $*"
  "$@"
}

# 서버 추가
for server in "${TO_ADD[@]+"${TO_ADD[@]}"}"; do
  [[ -z "$server" ]] && continue
  CONFIG=$(jq -c ".mcpServers[\"$server\"]" "$MCP_JSON")
  echo "[ADD] $server"
  run_cmd claude mcp add-json --scope "$SCOPE" "$server" "$CONFIG"
  echo ""
done

# 서버 업데이트 (remove + add)
for server in "${TO_UPDATE[@]+"${TO_UPDATE[@]}"}"; do
  [[ -z "$server" ]] && continue
  CONFIG=$(jq -c ".mcpServers[\"$server\"]" "$MCP_JSON")
  echo "[UPDATE] $server"
  run_cmd claude mcp remove --scope "$SCOPE" "$server" 2>/dev/null || true
  run_cmd claude mcp add-json --scope "$SCOPE" "$server" "$CONFIG"
  echo ""
done

# 서버 제거
for server in "${TO_REMOVE[@]+"${TO_REMOVE[@]}"}"; do
  [[ -z "$server" ]] && continue
  echo "[REMOVE] $server"
  run_cmd claude mcp remove --scope "$SCOPE" "$server"
  echo ""
done

echo "=== Reconcile complete ==="
