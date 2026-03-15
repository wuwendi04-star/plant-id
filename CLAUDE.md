# Plant ID — Claude Code Workflow

## Mandatory Pipeline

Every task MUST follow these 8 stages in order. Use TodoWrite to track each stage.

```
Stage 1: PLAN      → Use planner agent
Stage 2: TEST      → Use tdd-guide agent (write tests FIRST — RED phase)
Stage 3: IMPLEMENT → Implement to pass tests (GREEN phase)
Stage 4: REVIEW    → Use code-reviewer agent on ALL changed files
Stage 5: FIX       → Fix all CRITICAL and HIGH issues from review
Stage 6: SECURITY  → Use security-reviewer agent on all changes
Stage 7: VERIFY    → Run xcodebuild test, confirm 80%+ coverage
Stage 8: PR        → Create PR with full summary and test plan checklist
```

**Do NOT skip stages.** Do NOT proceed to the next stage until the current one is complete.

---

## Session Start Checklist

At the start of every session:

1. Read `TASK.md` in the worktree root (if it exists) to understand scope and acceptance criteria
2. If `TASK.md` does not exist, create it before doing any other work:
   ```markdown
   # Task: [brief description]
   ## Scope
   [what will change]
   ## Acceptance Criteria
   - [ ] criteria 1
   - [ ] criteria 2
   ## Done When
   [clear definition of done]
   ```
3. Create a TodoWrite list mapping each pipeline stage to concrete subtasks

---

## Session End Checklist

Before ending a session, verify ALL of the following:

- [ ] All TodoWrite tasks are `completed` (none `pending` or `in_progress`)
- [ ] `xcodebuild test` passed (0 failures)
- [ ] Code review was performed by `code-reviewer` agent
- [ ] Security review was performed by `security-reviewer` agent
- [ ] PR was created (or task is explicitly not at PR stage yet, documented in TASK.md)
- [ ] TASK.md acceptance criteria are all checked off

---

## Agent Reference

| Stage | Agent | How to invoke |
|-------|-------|---------------|
| Plan | `planner` | Use Agent tool with `subagent_type: "everything-claude-code:planner"` |
| TDD | `tdd-guide` | Use Agent tool with `subagent_type: "everything-claude-code:tdd-guide"` |
| Review | `code-reviewer` | Use Agent tool with `subagent_type: "everything-claude-code:code-reviewer"` |
| Security | `security-reviewer` | Use Agent tool with `subagent_type: "everything-claude-code:security-reviewer"` |
| E2E | `e2e-runner` | Use Agent tool with `subagent_type: "everything-claude-code:e2e-runner"` |

---

## Project Stack

- **Language**: Swift 6 + SwiftUI
- **Platform**: iOS 17+
- **Architecture**: MVVM + Repository pattern, SwiftData, @Observable
- **Test framework**: Swift Testing (unit) + XCTest (UI)
- **Build tool**: xcodegen (`project.yml`) → Xcode (`PlantID.xcodeproj`)
- **Commands**:
  - Generate project: `xcodegen generate`
  - Unit tests: `xcodebuild test -scheme PlantID -destination 'platform=iOS Simulator,name=iPhone 16'`
  - Build: `xcodebuild build -scheme PlantID -destination 'platform=iOS Simulator,name=iPhone 16'`

---

## Quality Standards

- **Test coverage**: 80% minimum (unit + integration)
- **No CRITICAL or HIGH issues** from code-reviewer before PR
- **No hardcoded secrets** — use environment variables or Keychain
- **Files**: max 800 lines, prefer 200–400 lines
- **Functions**: max 50 lines
- **Immutability**: always return new objects, never mutate state in-place

---

## Git Workflow

- Branch: one feature/fix per branch (worktree)
- Commits: `feat:`, `fix:`, `test:`, `refactor:`, `chore:`, `ci:`, `docs:`
- PRs: target `main`, require CI to pass

---

## Known Bug Patterns (avoid repeating)

### App Intents / Shortcuts — must set `openAppWhenRun = true`
Any `AppIntent` that needs to **open the main app** MUST declare:
```swift
static let openAppWhenRun: Bool = true
```
Without it, the intent runs in the Shortcuts extension process and `UIApplication.shared.open()` is silently ignored — the app never opens.

### In-app language switching — must use Bundle, not just `.locale` environment
`.environment(\.locale, someLocale)` only affects date/number **formatting**. It does NOT change which `.strings` file SwiftUI uses for `Text("key")` lookups.

To switch language at runtime without restart:
1. Add a `bundle` computed property to `LanguageManager` that loads the correct `.lproj` bundle
2. Create a custom `EnvironmentKey` (`localizedBundle`) and inject `languageManager.bundle`
3. In every view, read `@Environment(\.localizedBundle) private var bundle` and use `Text("key", bundle: bundle)`
