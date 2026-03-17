#!/usr/bin/env bash
# Stop hook: Quality gate enforcer
# Runs before Claude Code session ends.
# Outputs warnings if quality gates are not met — Claude should address them
# before finishing the session.

set -euo pipefail

WORKTREE_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
TASK_FILE="$WORKTREE_ROOT/TASK.md"
WARNINGS=()

# Gate 1: TASK.md must exist
if [[ ! -f "$TASK_FILE" ]]; then
  WARNINGS+=("TASK.md not found. Create it to define task scope and acceptance criteria.")
fi

# Gate 2: TASK.md acceptance criteria must all be checked
if [[ -f "$TASK_FILE" ]]; then
  UNCHECKED=$(grep -c '^\- \[ \]' "$TASK_FILE" 2>/dev/null || true)
  if [[ "$UNCHECKED" -gt 0 ]]; then
    WARNINGS+=("$UNCHECKED unchecked acceptance criteria remain in TASK.md.")
  fi
fi

# Gate 3: Tests must have been run (look for test results in build output)
if [[ -d "$WORKTREE_ROOT/app/build/test-results" ]]; then
  FAILED=$(find "$WORKTREE_ROOT/app/build/test-results" -name "*.xml" -exec grep -l 'failures="[1-9]' {} \; 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$FAILED" -gt 0 ]]; then
    WARNINGS+=("$FAILED test result file(s) contain failures. Run ./gradlew test and fix all failures.")
  fi
else
  # No test results yet — only warn if there are modified Kotlin files
  CHANGED_KT=$(git diff --name-only HEAD 2>/dev/null | grep '\.kt$' | wc -l | tr -d ' ')
  if [[ "$CHANGED_KT" -gt 0 ]]; then
    WARNINGS+=("Kotlin files were modified but no test results found. Run: ./gradlew test")
  fi
fi

# Gate 4: Recent commit history check for review evidence
# Check if code-reviewer was invoked this session (heuristic: look for review artifacts)
LAST_COMMITS=$(git log --oneline -10 2>/dev/null || true)
if echo "$LAST_COMMITS" | grep -qi 'review\|fix.*review\|address.*review' > /dev/null 2>&1; then
  : # Review evidence found in commits
else
  CHANGED_KT=$(git diff --name-only HEAD 2>/dev/null | grep '\.kt$' | wc -l | tr -d ' ')
  STAGED_KT=$(git diff --cached --name-only 2>/dev/null | grep '\.kt$' | wc -l | tr -d ' ')
  if [[ "$((CHANGED_KT + STAGED_KT))" -gt 0 ]]; then
    WARNINGS+=("Kotlin files changed but no code review evidence in recent commits. Use the code-reviewer agent.")
  fi
fi

# Output results
if [[ "${#WARNINGS[@]}" -eq 0 ]]; then
  echo "✅ Quality gates passed. Session can end cleanly."
  exit 0
else
  echo "⚠️  Quality Gate Warnings — Address before ending session:"
  echo ""
  for i in "${!WARNINGS[@]}"; do
    echo "  $((i+1)). ${WARNINGS[$i]}"
  done
  echo ""
  echo "Fix the above issues or update TASK.md if the scope changed."
  # Exit 0 so Claude Code doesn't crash, but Claude should read and act on warnings
  exit 0
fi
