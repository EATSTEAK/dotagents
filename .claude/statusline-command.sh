#!/usr/bin/env bash

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')

# Colors (ANSI 256 / truecolor approximations matching Starship palette)
RESET="\033[0m"
# Segment backgrounds
BG_PURPLE="\033[48;2;163;174;210m"   # #a3aed2
BG_BLUE="\033[48;2;118;159;240m"     # #769ff0
BG_DARK="\033[48;2;57;66;96m"        # #394260
BG_DARKER="\033[48;2;33;39;54m"      # #212736
BG_DARKEST="\033[48;2;29;34;48m"     # #1d2230
# Foregrounds
FG_BLACK="\033[38;2;9;12;12m"        # #090c0c
FG_WHITE="\033[38;2;227;229;229m"    # #e3e5e5
FG_BLUE="\033[38;2;118;159;240m"     # #769ff0
FG_PURPLE="\033[38;2;163;174;210m"   # #a3aed2
FG_ACCENT="\033[38;2;160;169;203m"   # #a0a9cb

# Powerline arrows (need a Nerd Font)
SEP_RIGHT=""
SEP_THIN=""

# Shorten path: replace $HOME with ~, truncate to last 3 segments
if [ -n "$cwd" ]; then
    short_dir="${cwd/#$HOME/\~}"
    # Truncate to last 3 path segments
    IFS='/' read -ra parts <<< "$short_dir"
    total=${#parts[@]}
    if [ "$total" -gt 3 ]; then
        short_dir="…/${parts[$((total-2))]}/${parts[$((total-1))]}/${parts[$total]}"
    fi
else
    short_dir="$(pwd | sed "s|$HOME|~|")"
fi

# Git branch (skip optional locks)
git_branch=""
if git -C "${cwd:-$(pwd)}" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "${cwd:-$(pwd)}" -c core.fsync=none symbolic-ref --short HEAD 2>/dev/null || git -C "${cwd:-$(pwd)}" -c core.fsync=none rev-parse --short HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        git_branch=" $branch"
    fi
fi

# Vim mode indicator
vim_indicator=""
if [ -n "$vim_mode" ]; then
    if [ "$vim_mode" = "NORMAL" ]; then
        vim_indicator=" N"
    elif [ "$vim_mode" = "INSERT" ]; then
        vim_indicator=" I"
    fi
fi

# Context usage bar
context_info=""
if [ -n "$used" ] && [ "$used" != "null" ]; then
    used_int=${used%.*}
    context_info=" ${used_int}%"
fi

# Model short name
model_short=""
if [ -n "$model" ] && [ "$model" != "null" ]; then
    model_short=" $model"
fi

# Time
time_str=$(date +%H:%M)

# Build the status line
output=""

# Segment 1: directory (purple bg)
output+="${BG_PURPLE}${FG_BLACK} ${short_dir} ${RESET}"

# Separator purple -> blue
output+="${FG_PURPLE}${BG_BLUE}${SEP_RIGHT}${RESET}"

# Segment 2: git branch (blue bg)
if [ -n "$git_branch" ]; then
    output+="${BG_BLUE}${FG_WHITE}${git_branch} ${RESET}"
    output+="${FG_BLUE}${BG_DARK}${SEP_RIGHT}${RESET}"
else
    output+="${FG_BLUE}${BG_DARK}${SEP_RIGHT}${RESET}"
fi

# Segment 3: model + context (dark bg)
if [ -n "$model_short" ]; then
    output+="${BG_DARK}${FG_BLUE}${model_short}${context_info} ${RESET}"
    output+="${FG_DARK}${BG_DARKEST}${SEP_RIGHT}${RESET}"
else
    output+="${FG_DARK}${BG_DARKEST}${SEP_RIGHT}${RESET}"
fi

# Segment 4: time (darkest bg)
output+="${BG_DARKEST}${FG_ACCENT}  ${time_str} ${RESET}"
output+="${FG_DARKEST}${SEP_RIGHT}${RESET}"

# Vim mode (if active)
if [ -n "$vim_indicator" ]; then
    output+=" ${FG_PURPLE}${vim_indicator}${RESET}"
fi

printf "%b" "$output"
