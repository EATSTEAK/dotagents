#!/usr/bin/env bash
set -euo pipefail

AGENTS_DIR="$HOME/.agents"
BACKUP_DIR="$AGENTS_DIR/.backups/$(date +%Y%m%d_%H%M%S)"

# 심볼릭 링크 정의: "링크경로|대상경로"
LINKS=(
  "$HOME/.claude/commands|$AGENTS_DIR/commands"
  "$HOME/.roo/commands|$AGENTS_DIR/commands"
  "$HOME/.roo/skills|$AGENTS_DIR/skills"
  "$HOME/.claude/skills|$AGENTS_DIR/skills"
  "$HOME/.claude/settings.json|$AGENTS_DIR/.claude/settings.json"
  "$HOME/.roo/rules|$AGENTS_DIR/.roo/rules"
)

backup_item() {
  local src="$1"
  if [ ! -e "$src" ] && [ ! -L "$src" ]; then
    return
  fi
  mkdir -p "$BACKUP_DIR"
  local rel_path="${src#$HOME/}"
  local backup_dest="$BACKUP_DIR/$rel_path"
  mkdir -p "$(dirname "$backup_dest")"
  cp -a "$src" "$backup_dest"
  echo "  백업: $src -> $backup_dest"
}

create_link() {
  local link_path="$1"
  local target="$2"

  # 대상이 존재하는지 확인
  if [ ! -e "$target" ]; then
    echo "  [오류] 대상 없음: $target"
    return 1
  fi

  # 이미 올바른 심볼릭 링크인지 확인
  if [ -L "$link_path" ]; then
    local current_target
    current_target=$(readlink "$link_path")
    if [ "$current_target" = "$target" ]; then
      echo "  [스킵] 이미 올바른 링크: $link_path -> $target"
      return 0
    fi
    # 잘못된 링크 -> 백업 후 제거
    echo "  [업데이트] 기존 링크 교체: $link_path"
    backup_item "$link_path"
    rm "$link_path"
  elif [ -e "$link_path" ]; then
    # 실제 파일/디렉토리 -> 백업 후 제거
    echo "  [교체] 실제 파일/디렉토리를 링크로 교체: $link_path"
    backup_item "$link_path"
    rm -rf "$link_path"
  fi

  # 부모 디렉토리 생성
  mkdir -p "$(dirname "$link_path")"

  # 심볼릭 링크 생성
  ln -s "$target" "$link_path"
  echo "  [생성] $link_path -> $target"
}

echo "=== ~/.agents 심볼릭 링크 설정 ==="
echo ""

for entry in "${LINKS[@]}"; do
  IFS='|' read -r link_path target <<< "$entry"
  create_link "$link_path" "$target"
done

echo ""
echo "=== 완료 ==="
