#!/bin/bash
# Claude Code status line script
# Mirrors the information powerline-go shows: host, cwd, git branch,
# plus Claude-specific info: model, context usage, and rate limit.
# Runs on every refresh, so forks are kept to a minimum: one jq call
# extracts all fields at once, one date call formats the reset time,
# and the rest is bash builtins (plus git when cwd is a repo).

input=$(cat)

# All fields in a single jq pass, joined with the ASCII unit separator.
# (Unlike tab, a non-whitespace IFS char never collapses runs of
# delimiters, so empty fields keep their position for read.)
IFS=$'\x1f' read -r cwd model used_pct five_hr_pct five_hr_reset effort < <(
    jq -r '[
        (.cwd // .workspace.current_dir // ""),
        (.model.display_name // ""),
        (.context_window.used_percentage // ""),
        (.rate_limits.five_hour.used_percentage // ""),
        (.rate_limits.five_hour.resets_at // ""),
        (.effort.level // "")
    ] | map(tostring) | join("\u001f")' <<<"$input"
)

# Shorten "(1M context)" -> "(1M)" in the model display name
model=${model/(1M context)/(1M)}

host=${HOSTNAME%%.*}

# Shorten cwd: replace $HOME with ~
home_dir="${HOME:-$(getent passwd "$(whoami)" | cut -d: -f6)}"
short_cwd=${cwd/#"$home_dir"/\~}

# Git branch, falling back to a short hash when detached; both commands
# fail quietly when cwd isn't in a git repo
git_branch=""
if [ -n "$cwd" ]; then
    git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
                 || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

# Build the line — ctx first, then @host, cwd, git, model
line=""

if [ -n "$used_pct" ]; then
    printf -v used_fmt "%.0f" "$used_pct"
    line="ctx:${used_fmt}%"
fi

if [ -n "$five_hr_pct" ]; then
    printf -v five_hr_fmt "%.0f" "$five_hr_pct"
    if [ -n "$five_hr_reset" ]; then
        # %p is AM/PM; stripping the trailing M leaves the A/P suffix
        reset=$(date -d "@${five_hr_reset}" '+%-I:%M%p')
        line="${line}${line:+  }${five_hr_fmt}%/${reset%[Mm]}"
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
