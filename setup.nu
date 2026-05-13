#!/usr/bin/env nu

let agents_dir = ($nu.home-path | path join ".agents")
let backup_dir = ($agents_dir | path join ".backups" (date now | format date "%Y%m%d_%H%M%S"))

let links = [
  { link: ($nu.home-path | path join ".roo" "skills"), target: ($agents_dir | path join "skills") }
  { link: ($nu.home-path | path join ".claude" "skills"), target: ($agents_dir | path join "skills") }
  { link: ($nu.home-path | path join ".config" "opencode" "skills"), target: ($agents_dir | path join "skills") }
  { link: ($nu.home-path | path join ".config" "opencode" "opencode.json"), target: ($agents_dir | path join ".opencode" "opencode.json") }
  { link: ($nu.home-path | path join ".claude" "settings.json"), target: ($agents_dir | path join ".claude" "settings.json") }
  { link: ($nu.home-path | path join ".claude" "statusline-command.sh"), target: ($agents_dir | path join ".claude" "statusline-command.sh") }
  { link: ($nu.home-path | path join ".roo" "rules"), target: ($agents_dir | path join ".roo" "rules") }
  { link: ($nu.home-path | path join ".hermes" "config.yaml"), target: ($agents_dir | path join "hermes" "config.yaml") }
]

def ps-quote [value: string] {
  "'" + ($value | str replace --all "'" "''") + "'"
}

def get-link-target [link_path: string] {
  let script = ([
    "$item = Get-Item -LiteralPath " (ps-quote $link_path) " -Force -ErrorAction SilentlyContinue; "
    "if ($null -ne $item -and $item.LinkType -eq 'SymbolicLink') { $item.Target }"
  ] | str join)

  (powershell -NoProfile -Command $script | str trim)
}

def remove-item [item_path: string] {
  let script = (["Remove-Item -LiteralPath " (ps-quote $item_path) " -Force -Recurse"] | str join)
  powershell -NoProfile -Command $script
}

def new-symlink [link_path: string, target: string] {
  let target_type = ($target | path type)
  let item_type = if $target_type == "dir" { "Directory" } else { "File" }
  let script = ([
    "New-Item -ItemType " $item_type
    " -Path " (ps-quote $link_path)
    " -Target " (ps-quote $target)
    " | Out-Null"
  ] | str join)

  powershell -NoProfile -Command $script
}

def backup-item [src: string, backup_dir: string] {
  if (($src | path type) == null) {
    return
  }

  mkdir $backup_dir
  let rel_path = ($src | path relative-to $nu.home-path)
  let backup_dest = ($backup_dir | path join $rel_path)
  mkdir ($backup_dest | path dirname)
  cp --recursive $src $backup_dest
  print $"  백업: ($src) -> ($backup_dest)"
}

def create-link [link_path: string, target: string, backup_dir: string] {
  let target_type = ($target | path type)
  if ($target_type == null) {
    print $"  [오류] 대상 없음: ($target)"
    error make { msg: $"대상 없음: ($target)" }
  }

  let link_type = ($link_path | path type)
  if ($link_type == "symlink") {
    let current_target = (get-link-target $link_path)
    if ($current_target == $target) {
      print $"  [스킵] 이미 올바른 링크: ($link_path) -> ($target)"
      return
    }

    print $"  [업데이트] 기존 링크 교체: ($link_path)"
    backup-item $link_path $backup_dir
    remove-item $link_path
  } else if ($link_type != null) {
    print $"  [교체] 실제 파일/디렉터리를 링크로 교체: ($link_path)"
    backup-item $link_path $backup_dir
    remove-item $link_path
  }

  mkdir ($link_path | path dirname)
  new-symlink $link_path $target
  print $"  [생성] ($link_path) -> ($target)"
}

print "=== ~/.agents 심볼릭 링크 설정 ==="
print ""

for entry in $links {
  create-link $entry.link $entry.target $backup_dir
}

print ""

let env_file = ($agents_dir | path join ".env")
let shell_config = ($nu.default-config-dir | path join "config.nu")
let func_marker = "# ~/.agents claude wrapper"

print "=== claude wrapper function 설정 ==="
if ($env_file | path exists) {
  mkdir ($shell_config | path dirname)
  let existing_config = if ($shell_config | path exists) { open --raw $shell_config } else { "" }

  if not ($existing_config | str contains $func_marker) {
    let wrapper = r#'

# ~/.agents claude wrapper
def --wrapped claude [...args] {
  let env_file = ($nu.home-path | path join ".agents" ".env")
  let env_vars = if ($env_file | path exists) {
    open --raw $env_file
    | lines
    | each { |line| $line | str trim }
    | where { |line| $line != "" and not ($line | str starts-with "#") and ($line | str contains "=") }
    | each { |line|
        let normalized = if ($line | str starts-with "export ") { $line | str replace --regex '^export\s+' "" } else { $line }
        let parts = ($normalized | split row "=")
        let key = ($parts | first | str trim)
        let value = ($parts | skip 1 | str join "=" | str trim)

        { key: $key, value: ($value | str trim --char '"' | str trim --char "'") }
      }
    | reduce -f {} { |it, acc| $acc | upsert $it.key $it.value }
  } else {
    {}
  }

  with-env $env_vars { ^claude ...$args }
}
'#

    $wrapper | save --append $shell_config
    print $"  [추가] ($shell_config) 에 claude wrapper function 추가됨"
  } else {
    print $"  [스킵] ($shell_config) 에 이미 claude wrapper 있음"
  }
} else {
  print $"  [경고] .env 파일이 없습니다: ($env_file)"
  print "  .env.example 을 참고하여 .env 파일을 생성하세요."
}

print ""
print "=== MCP 서버 동기화 ==="
let mcp_script = ($agents_dir | path join "scripts" "reconcile-mcp.sh")
let mcp_json = ($agents_dir | path join ".mcp.json")
if (($mcp_script | path exists) and ($mcp_json | path exists)) {
  let answer_raw = (input "  .mcp.json 기반으로 Claude Code MCP 서버를 동기화할까요? (Y/n) ")
  let answer = if (($answer_raw | str trim) == "") { "Y" } else { $answer_raw | str trim }

  if (($answer | str downcase) == "y") {
    if (which bash | is-not-empty) {
      bash $mcp_script
    } else {
      print "  [오류] bash를 찾을 수 없어 MCP 동기화를 실행할 수 없습니다."
    }
  } else {
    print "  [스킵] MCP 동기화를 건너뜁니다."
  }
} else {
  print "  [스킵] reconcile-mcp.sh 또는 .mcp.json 이 없습니다."
}

print ""
print "=== 완료 ==="
