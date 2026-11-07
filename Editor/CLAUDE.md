# Documentation and Plan Files
- All plan files go in `/docs/plans/YYYYMMDD-<purpose slug>.md`
- All design docs go in `/docs/design/YYYYMMDD-<purpose slug>.md`
- All other docs go somewhere in `/docs` with the same naming style

# Godot
We are using Godot 4.7.2 for this project.

**Non-Nodes don't hold Nodes.** `RefCounted`, `Resource` and autoload classes never keep a Node
(or Node-typed `Variant`) in a member; using one as a parameter within a call is fine. Anything
that must hold scene nodes across frames is itself a Node, parented into the scene.

**Every `await` is a lifetime boundary.**
- Tweens: `node.create_tween()` on the animated node, never `get_tree().create_tween()`.
- Tree timers: `get_tree().create_timer(t, false)`. The default `process_always = true` ignores pause.
- After an `await`, the first line before touching nodes is `if not is_inside_tree(): return`
  (or `is_instance_valid(x)` for a held reference). One gate at the resume point, not one per line.
- Never `await tween.finished` on a tween another path may `kill()`. `kill()` doesn't emit
  `finished`, so the coroutine is silently abandoned.

**Loops re-check what their body can break.** If an iteration can free an object, free a node, or empty
the collection, test for it at the top of each iteration and `break`.

## Data & dispatch

**Never dispatch by string.** No `obj.call("name")`, `obj.get("name")`, or concatenated property
names. Call through a statically typed reference; dispatch tables hold `Callable`s taken from one
(`td.on_combat_start`).

**Use one function per formula (DRY).** Calculating buffers, margins, transitions, assembly operations, and anything else that uses a repeatable formula should be defined in one place and reused.

## Structure & style

- **Nodes by unique name or injection:** `@onready var x: T = %Name`, or passed in by the owner.
  Never `get_node()`, `$Path`, `find_child()` or absolute paths. `%Name` is scene-local; across
  scenes the owner passes the reference down.
- **Scenes in `.tscn`:** controls, layout, theme overrides and `[connection]` binds live in the
  scene file, not `_ready()`. Transient effects (tweens, particles, sprite animations) may be built
  in code.
- **Components don't reference their orchestrator or each other;** they talk upward through signals the orchestrator connects.
- **Signals:** `sig.emit()` / `sig.connect()`, never `emit_signal("sig")`.

## Tests

Tests are data-driven: use the game's own constants, enums, sizes and data, never copied literals.

## Verifying changes

Use the cheapest rung that proves *this* change.

| Rung             | Use for                                                                                                                                                                | Not for                                                                         |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| 1. Headless      | import/`.uid` generation; class-cache rebuild; boot check (`--headless --quit-after 5`, grep `SCRIPT ERROR`); a scene harness (`--headless --path . res://dev/x.tscn`) | anything needing autoloads under bare `--script`, the rendered tree, or visuals |
| 2. GUT           | any gameplay, combat or data change (loads autoloads)                                                                                                                  | visuals                                                                         |
| 3. Run the scene | visual/UI changes: run the `.tscn` (not headless), capture the screen                                                                                                  | —                                                                               |
| 4. Ask a Human   | what only human eyes or judgment can confirm                                                                                                                           | —                                                                               |
- Never use raw `gut_cmdln.gd -gtest=`. It adds to the config's dirs and runs everything.
- After adding a `class_name`: `godot --headless --path . --import` once before running tests.
- Scoped runs while iterating; **the full suite** after each major task and before any commit.

Run Godot from **Bash**, never PowerShell. `.import` churn from headless runs is expected; leave it.

## Comments

- Do not add comments by default.
- Most files should contain zero comments.
- NEVER state decisions made during planning sessions
- NEVER state decisions made by the spec
- NEVER narrate code, control flow, obvious intent, or recent changes.
- NEVER state differential changes between old and new code.
- NEVER restate names, types, conditions, or function behavior.
- NEVER leave empty boilerplate, placeholder todos, or verbose AI-generated summaries.
- NEVER write ephemeral state (e.g. whether a test passed or failed prior or after this change).
- Prefer clearer code over explanatory comments.
- Only comment non-obvious business rules, external quirks/workarounds, or dangerous edge cases.
- If a competent maintainer can infer the reason from the code, delete the comment.
- Before finishing, remove every comment you added that is not strictly necessary.
- Comments are ALWAYS present tense: what the code does and the rule it encodes, never what changed. History belongs in the commit message.
