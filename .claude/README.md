# ~/.claude — configuration layering

This README is tracked in yadm. It maps which files here sync across
machines and which are deliberately machine-local.

| file | in yadm? | role |
|---|---|---|
| `settings.json` | yes | settings wanted on EVERY machine (model, env, statusline, hooks) |
| `settings.machine.json` | **never** | overrides for THIS machine only — see below |
| `settings.local.json` | **never** | written by Claude Code itself: this is the *project-local* settings file for sessions whose cwd is under `$HOME` outside any repo (its "always allow" permission approvals land here). It is NOT a user-level tier and is only loaded by such sessions — do not put settings here expecting global effect. |
| `hooks/` | yes | hook scripts referenced by hook entries. `rg_replace_guard.py` is the portable python guard, used by machines without the Rust build (see the guard section below). |
| `CLAUDE.md` | yes | global instructions for Claude, all projects |
| `README.md` | yes | this file |

## Machine-local settings: `settings.machine.json`

Claude Code has **no built-in user-level local settings file** (verified
empirically 2026-07-28 on v2.1.220: hooks placed in `~/.claude/settings.local.json`
do not load; docs list only managed → CLI flags → project-local → project →
user). The machine layer is provided by the `claude()` wrapper in `.bashrc`
— the same pattern as `.bashrc.local`:

```
claude() {
    local machine="$HOME/.claude/settings.machine.json"
    if [[ -f "$machine" ]]; then
        command claude --settings "$machine" "$@"
    else
        command claude "$@"
    fi
}
```

When `settings.machine.json` exists it is passed as a `--settings` layer
(the CLI-flag tier). Verified merge semantics (2026-07-28, v2.1.220):

- **Both tiers fully load** — this is a merge, not a replacement.
- **Same-key values**: the machine file wins (flag tier ranks above user).
  Put ONLY the keys that should differ on this machine; everything else
  inherits from `settings.json`.
- **`env`**: merges per-variable (a machine env var does not drop the
  synced ones, e.g. `CLAUDE_CODE_EFFORT_LEVEL` survives).
- **`permissions`**: allow/deny arrays accumulate across tiers.
- **`hooks`**: union — hooks from BOTH files run. Never define the same
  hook in both tiers or it executes twice per event.

Caveats:

- Applies only to launches that go through the shell function. IDE
  extensions, SDK use, and anything exec'ing the `claude` binary directly
  bypass it.
- If you need to pass your own `--settings` for an experiment, call
  `command claude --settings <file> ...` to avoid stacking two flags.
- Setting up a new machine: the wrapper itself needs nothing (it no-ops
  until a `settings.machine.json` exists) — but the ripgrep guard DOES
  need setup: create that file with one of the entries from the guard
  section below, or the machine runs with no guard at all.

Full investigation writeup (probes, findings, design rationale):
`~/proj/private/claude-machine-local-settings.md`.

## The ripgrep `-r` guard: wired per machine

The PreToolUse guard that denies ripgrep's short `-r` (it means `--replace`,
not recursive) is deliberately NOT in the synced `settings.json`: the fast
engine is a locally-built binary, and hooks merge across tiers, so a synced
entry would run *in addition to* the machine one. Each machine instead
carries exactly one entry in its `settings.machine.json`:

**Machine with the Rust build** (~0.7 ms/call, exec form — no shell; build
once with `cargo build --release` in `private/src/rg_replace_guard/`):

```json
"hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [ {
  "type": "command",
  "command": "/home/mgebis/proj/private/src/rg_replace_guard/target/release/rg_replace_guard",
  "args": [], "timeout": 10 } ] } ] }
```

**Machine without it** (~2 ms common case; needs only python3 — the script
is synced in `hooks/`, so this works on any machine as-is):

```json
"hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [ {
  "type": "command",
  "command": "payload=$(cat); case \"$payload\" in *rg*) printf '%s' \"$payload\" | python3 \"$HOME/.claude/hooks/rg_replace_guard.py\";; esac",
  "timeout": 10 } ] } ] }
```

Caveats of this arrangement (accepted for speed, 2026-07-28):

- The guard exists only where a `settings.machine.json` entry exists. A
  freshly synced machine is UNGUARDED until its entry is added.
- The machine file loads via the `claude()` wrapper, so launches that
  bypass the shell function (IDE extensions, SDK, exec'ing the binary
  directly) run without the guard — verified empirically. If either
  caveat starts to matter, the alternatives are: move the entry to
  `/etc/claude-code/managed-settings.json` (machine-local AND loads for
  every launch; needs sudo), or revert to the self-adapting synced
  command documented in `private/src/rg_replace_guard/README.md`.
