#!/usr/bin/env python3
"""PreToolUse guard: deny `rg -r`, the grep-habit flag that means --replace.

grep's -r means "recursive"; ripgrep's -r/--replace rewrites match output.
ripgrep recurses by default, so a short -r on an rg command is almost always
the grep habit, not an intended replacement. This hook denies such commands
with an explanation. The long form --replace is allowed: spelling it out
signals the replacement is intentional.

Reads the Claude Code hook JSON on stdin. Prints a PreToolUse "deny" JSON
on a match; prints nothing (exit 0) otherwise. Never blocks anything else.
"""
import json
import re
import shlex
import sys

# Short flags that consume a value: an 'r' after one of these in a cluster
# (e.g. -er) is that flag's argument, not --replace.
_VALUE_SHORT: frozenset[str] = frozenset("ABCEMefgjmtT")

# Long flags that consume the NEXT token as their value, so a following
# "-r" token is a value, not the replace flag (e.g. `rg -e -r` = pattern "-r").
_VALUE_LONG: frozenset[str] = frozenset({
    "--regexp", "--file", "--glob", "--iglob", "--ignore-file", "--pre",
    "--type", "--type-not", "--type-add", "--encoding", "--engine",
    "--colors", "--color", "--sort", "--sortr", "--max-count",
    "--max-columns", "--max-depth", "--max-filesize", "--threads",
    "--after-context", "--before-context", "--context",
    "--path-separator", "--context-separator",
})

_SEPARATOR_CHARS: frozenset[str] = frozenset("();<>|&")

_REASON: str = (
    "rg's -r flag means --replace (rewrite match output), NOT recursive - "
    "that's the grep flag. ripgrep recurses by default, so just drop the -r. "
    "If a replacement preview was actually intended, spell it --replace "
    "(the long form is allowed). [hook: ~/.claude/hooks/rg_replace_guard.py]"
)


def _cluster_has_replace(token: str) -> bool:
    """True if a short-flag token like -r, -nr, or -rfoo carries --replace."""
    if not token.startswith("-") or token.startswith("--") or len(token) < 2:
        return False
    for ch in token[1:]:
        if ch == "r":
            return True
        if not ch.isalpha() or ch in _VALUE_SHORT:
            return False  # rest of cluster is a flag value / not flags
    return False


def _tokens_have_rg_replace(tokens: list[str]) -> bool:
    scanning = False   # inside an rg invocation's option list
    skip_value = False  # previous token was a flag that takes a value
    for tok in tokens:
        if tok and all(ch in _SEPARATOR_CHARS for ch in tok):
            scanning = False
            skip_value = False
            continue
        if tok == "rg" or tok.endswith("/rg"):
            scanning = True
            skip_value = False
            continue
        if not scanning:
            continue
        if skip_value:
            skip_value = False
            continue
        if tok == "--":
            scanning = False  # only positional args from here
            continue
        if tok in _VALUE_LONG or (len(tok) == 2 and tok[1] in _VALUE_SHORT and tok[0] == "-"):
            skip_value = True
            continue
        if _cluster_has_replace(tok):
            return True
    return False


def _command_has_rg_replace(command: str) -> bool:
    # Newlines separate commands but shlex treats them as plain whitespace,
    # so join continuations and scan line by line.
    for line in command.replace("\\\n", " ").split("\n"):
        try:
            lex = shlex.shlex(line, posix=True, punctuation_chars=True)
            lex.whitespace_split = True
            tokens = list(lex)
        except ValueError:
            # Unlexable shell (heredoc body, unbalanced quote): fall back to
            # a naive split; quotes are lost but the scan stays conservative.
            tokens = [t for seg in re.split(r"[|;&()<>]+", line) for t in seg.split()]
        if _tokens_have_rg_replace(tokens):
            return True
    return False


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, UnicodeDecodeError):
        return 0
    if not isinstance(payload, dict) or payload.get("tool_name") != "Bash":
        return 0
    tool_input = payload.get("tool_input")
    command = tool_input.get("command", "") if isinstance(tool_input, dict) else ""
    if "rg" not in command:  # cheap pre-filter
        return 0
    if _command_has_rg_replace(command):
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": _REASON,
            }
        }))
    return 0


if __name__ == "__main__":
    sys.exit(main())
