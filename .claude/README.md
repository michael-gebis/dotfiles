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
- Setting up a new machine: nothing to do — the wrapper no-ops until a
  `settings.machine.json` is created there. (The ripgrep guard needs no
  machine file either; see its section below.)

Full investigation writeup (probes, findings, design rationale):
`~/proj/private/claude-machine-local-settings.md`.

## The ripgrep `-r` guard: self-adapting, synced

The PreToolUse guard that denies ripgrep's short `-r` (it means `--replace`,
not recursive) lives in the synced `settings.json` as one self-adapting hook
command: it execs the Rust build
(`~/proj/private/src/rg_replace_guard/target/release/rg_replace_guard`) when
that binary exists, else runs the python prefilter against the synced
`hooks/rg_replace_guard.py`. Consequences:

- **Fresh machine: the python guard is active immediately** after yadm
  sync/bootstrap — no setup; python3 is the only requirement (~2 ms common
  case, ~27 ms when a command mentions rg).
- **Upgrading a machine to the Rust engine is just a build**: clone private,
  `cargo build --release` in `src/rg_replace_guard/`. The hook probes the
  path on every call and switches over by itself (~1.6 ms flat). No
  settings change; `settings.machine.json` is not involved.
- The guard covers every launch (wrapper, IDE, SDK, direct binary) because
  it rides the user-tier settings, not the machine file.
- Deny messages end with a bracket tag naming the engine that fired —
  `[hook: ~/proj/private/src/rg_replace_guard]` (Rust) vs `[hook:
  ~/.claude/hooks/rg_replace_guard.py]` (python) — so it is always
  observable which one is running.

A pure exec-form wiring (0.7 ms; hook entry in `settings.machine.json`,
synced settings hook-free) was used briefly on 2026-07-28 and retired the
same day: it leaves a freshly synced machine — and any wrapper-bypassing
launch — with no guard at all (both verified). The ~0.9 ms/call saving was
judged not worth that. It remains documented in
`private/src/rg_replace_guard/README.md` alongside the other wirings.
