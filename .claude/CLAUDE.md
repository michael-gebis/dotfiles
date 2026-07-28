# Python
- When creating python files, always use type hints
- Always use uv instead of pip

# Utility functions
- prefer to use ripgrep/rg to grep
- rg's `-r` means `--replace`, NOT recursive (that's grep's flag) — rg recurses by
  default, so never pass `-r` for recursion. A PreToolUse hook
  (`~/.claude/hooks/rg_replace_guard.py`) denies short `-r`; spell out `--replace`
  on the rare occasion a replacement preview is actually intended.

# Claude Code settings layering
- `~/.claude/settings.json` is yadm-synced to every machine. Machine-local overrides go in
  `~/.claude/settings.machine.json` (NEVER tracked), loaded via the `claude()` wrapper in
  `.bashrc`. Tiers merge (machine wins same-key; env per-variable; permissions accumulate;
  hooks union — never define the same hook in both). Details: `~/.claude/README.md`.

# Repo layout — two conventions, and never assume which one you're in

Checkouts under `~/proj` follow one of two shapes. **Which level is the git root differs
between them**, so guessing costs a wrong `git -C` and a wrong reading of any relative path.

**`<project>/<branch>/…` — the worktree shape.** The directory under the project container is
named for the **git branch**, and *that* directory is the repo root. The container itself is a
plain directory, not a repo. Several branches can be checked out side by side. This shape is
used where worktrees are expected.

```
proj/gadget/                     plain dir  <- NOT a repo
proj/gadget/main/                repo root, branch "main"
proj/gadget/dev/                 repo root, branch "dev"          } same repo,
proj/gadget/X9/                 repo root, branch "X9"          } several branches
proj/ACME/firmware/           plain dir  <- NOT a repo
proj/ACME/firmware/FEATURE_FOO/    repo root, branch "FEATURE_FOO"
```

**`<project>/…` — the plain shape.** The project directory *is* the repo root.

```
proj/ACME/tools/          repo root, branch "master"
proj/private/                      repo root, branch "master"   (scripts/ is a SUBDIR of it)
```

**The habit: detect, don't pattern-match.** One call answers it from any depth:

```
git -C <path> rev-parse --show-toplevel
```

Do that before any `git` operation, before trusting a documented path, and before reading a
`file:line` citation as relative to something.

Three ways this bites, all observed:

- **`git -C <project>` fails** with "not a git repository" in the worktree shape, because the
  root is one level down. A doc saying "pinned to `../firmware` @ `<sha>`" is describing the
  *container*; the commit lives in `../firmware/<branch>/`.
- **A path can read like a subdirectory and be a branch.** `firmware/FEATURE_FOO` looks like
  "a subdir of the firmware repo" and is actually "the `FEATURE_FOO` branch checkout". So
  citations under it are relative to a **repo root**, not to a subdirectory.
- **The reverse also happens.** `private/scripts` genuinely *is* a subdirectory of the `private`
  repo, so that repo may carry unrelated changes in other subtrees — stage explicit paths when
  committing there, never `git add -A`.

**Other engineers may lay things out differently.** Treat both shapes as possible everywhere and
detect per repo, rather than learning "this project is shaped like that".
