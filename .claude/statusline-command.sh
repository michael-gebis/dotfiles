#!/bin/bash
# Claude Code status line script
# Mirrors the information powerline-go shows: user@host, cwd, git branch,
# plus Claude-specific info: model and context usage.

input=$(cat)

cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_hr_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
effort=$(echo "$input" | jq -r '.effort.level // empty')

# Shorten "(1M context)" -> "(1M)" in the model display name
model=${model/(1M context)/(1M)}

# user@host
user=$(whoami)
host=$(hostname -s)

# Shorten cwd: replace $HOME with ~
home_dir="${HOME:-$(getent passwd "$(whoami)" | cut -d: -f6)}"
short_cwd=$(echo "$cwd" | sed "s|^${home_dir}|~|")

# Git branch (skip optional lock; ignore errors if not a git repo)
git_branch=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
                 || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

# Build the line — ctx first, then @host, cwd, git, model
line=""

if [ -n "$used_pct" ]; then
    printf_pct=$(printf "%.0f" "$used_pct")
    line="ctx:${printf_pct}%"
fi

five_hr_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
if [ -n "$five_hr_pct" ]; then
    five_hr_fmt=$(printf "%.0f" "$five_hr_pct")
    if [ -n "$five_hr_reset" ]; then
        reset_time=$(date -d "@${five_hr_reset}" '+%-I:%M')
        reset_ampm=$(date -d "@${five_hr_reset}" '+%p' | head -c1)
        line="${line}${line:+  }${five_hr_fmt}%/${reset_time}${reset_ampm}"
    else
        line="${line}${line:+  }${five_hr_fmt}%"
    fi
fi

line="${line}${line:+  }@${host}  ${short_cwd}"

if [ -n "$git_branch" ]; then
    line="${line}  [${git_branch}]"
fi

if [ -n "$model" ]; then
    line="${line}  ${model}"
    if [ -n "$effort" ]; then
        line="${line} [${effort}]"
    fi
fi

printf "%s" "$line"
