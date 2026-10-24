# Can Claude Code hooks report Session State back to the owning Neovim?

Researched 2026-10-24 against Claude Code **v2.1.310** and Neovim **v0.11.7** (WSL2 Linux).
Every claim is either cited to a primary source or marked **[verified]**, meaning it was reproduced
in the local experiment described at the end.

## Answer

**Yes.** Start each session with `claude --settings <file>`, where the file holds hooks that run
`nvim --server "$NVIM" --remote-expr ...`. This works without touching `~/.claude/settings.json`.

- **Per process:** `--settings <file-or-json>` hooks are **added to** the user, project and local
  hooks; they do not replace them. Lists merge across scopes. [docs; verified]
- **`$NVIM` is inherited:** Neovim sets `$NVIM` for `:terminal` / `jobstart({term=true})`
  children, and hooks inherit Claude's environment. A hook calling `nvim --server "$NVIM" --remote-expr`
  reached the owning nvim in about 40 ms. [docs; verified]
- **State mapping** (all verified live):
  - **working**: `UserPromptSubmit`. Also `PreToolUse` and `PostToolUse`, which move a session out
    of waiting once a prompt has been answered.
  - **waiting**: `PermissionRequest`. It fires immediately, about 20 ms after `PreToolUse`, for both
    tool permission prompts **and `AskUserQuestion`** (`tool_name` tells you which). The
    `Notification`/`permission_prompt` event is a weaker signal: it fires only after about 6 s of no
    keystrokes.
  - **idle**: `Stop`. `Notification` with `notification_type: "idle_prompt"` follows about 60 s later.
  - **exited**: `SessionEnd` (it fired even when the job was killed with `jobstop`). Use the
    terminal job's `on_exit` as the authoritative signal.
- **Gotchas:**
  - **Stop does not fire on user interrupt** (Esc, or rejecting a permission prompt). [docs; verified]
  - `SubagentStop` also fires for internal agents right after `Stop`.
  - **`nvim --server` exits 2 when it can't connect, and exit 2 is Claude's "blocking error" code.**
    On `PreToolUse` that would block the tool, and on `Stop` it would keep Claude running. Always
    end the hook command with `|| true` / `exit 0`. [verified]
  - Synchronous hooks block Claude until they finish. Use `"async": true` or keep hooks very fast.
    Set a small `timeout`.

## 1. Hook events and the working / waiting / idle mapping

Events from the hooks reference ([code.claude.com/docs/en/hooks][hooks]) that matter here:

| Event | Fires when (docs) | Use for state |
|---|---|---|
| `SessionStart` | Session begins or resumes. Matchers: `startup`, `resume`, `clear`, `compact`, `fork` | -> idle (session registered; capture `session_id`) |
| `UserPromptSubmit` | Prompt submitted, before Claude processes it. Also fires for `/loop` iterations, background subagent reports and messages from other sessions | -> **working** |
| `PreToolUse` | Before a tool call executes | -> working (also clears waiting) |
| `PermissionRequest` | "Runs only when Claude is about to ask for permission, or would auto-deny a call that can't prompt" | -> **waiting** |
| `PostToolUse` / `PostToolUseFailure` | After a tool call succeeds / fails | -> working (the prompt was answered) |
| `Notification` | Claude Code sends a notification (see below) | waiting / idle confirmation |
| `Stop` | Main agent finished responding. "Does not run if the stoppage occurred due to a user interrupt. API errors fire StopFailure instead" | -> **idle** |
| `StopFailure` | Turn ended due to an API error. Payload has `error`, `error_details` | -> idle (or an error state) |
| `SubagentStop` | A subagent finishes. Internal agents (prompt suggestions, `/btw`) also fire it | ignore for top-level state |
| `SessionEnd` | Session terminates. `reason`: `clear`, `resume`, `logout`, `prompt_input_exit`, `other` | -> **exited** |

There are many other events (`PreCompact`, `CwdChanged`, `TaskCreated`, `Elicitation`, and so on).
See [hooks].

### Notification: does it distinguish permission prompts from idle input waiting?

Yes, through `notification_type`, which is also the matcher value. The payload is `message`, an
optional `title`, and `notification_type` ([hooks], "Notification"). The matcher values are
`permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog`, `elicitation_url_dialog`,
`elicitation_complete`, `elicitation_response`, `agent_needs_input`, `agent_completed`, `quota_auto_resume_*`
and `plugin_notification`.

Timing ([hooks]):

- **`idle_prompt`** "fires about 60 seconds after Claude finishes responding, if you haven't typed
  since and no background agent is still running." [verified: 60.0 s after `Stop`,
  `"message": "Claude is waiting for your input"`]
- **`permission_prompt`** "fires once the permission prompt has waited about six seconds. Each
  keystroke defers it ... It doesn't fire if you or a PermissionRequest hook answer first."
  [verified: 6.0 s after `PermissionRequest`, `"message": "Claude needs your permission"`. It also
  fired with the same `permission_prompt` type and message for `AskUserQuestion`.]
- Notification hooks cannot block or modify the notification.

**Recommendation:** drive *waiting* from `PermissionRequest`, which fires immediately, and *idle*
from `Stop`. Treat `Notification` only as a backup or for an "attention" badge. The delays and the
keystroke deferral make it unsuitable as the primary signal.

### Observed event sequence [verified]

These come from one interactive session in an nvim terminal buffer started with
`--permission-mode default`. Timestamps are wall-clock seconds, shown as offsets.

```
+0.00  SessionStart       source=startup, model=claude-opus-5-5
+10.2  UserPromptSubmit   prompt="Use the Bash tool to run exactly: touch made.txt"
+13.8  PreToolUse         tool_name=Bash
+13.9  PermissionRequest  tool_name=Bash            <- permission dialog visible
+19.9  Notification       notification_type=permission_prompt (6 s later, nobody typing)
       (user approves)
+39.6  PostToolUse        tool_name=Bash
+41.5  Stop               last_assistant_message="I ran `touch made.txt` ..."
+43.6  SubagentStop       agent_type=""  (internal agent, NOT user-visible work)
+101.6 Notification       notification_type=idle_prompt (60 s after Stop)
```

`AskUserQuestion` produced `PreToolUse(tool_name=AskUserQuestion)` -> `PermissionRequest(tool_name=AskUserQuestion)`
-> `Notification(permission_prompt)` 6 s later. A question to the user is therefore detectable the
same way as a permission prompt.

Rejecting a permission prompt with Esc printed "Interrupted · What should Claude do instead?". After
that, **no `Stop` and no `PostToolUse`** fired. The session was idle at the prompt, but no hook said so
until `idle_prompt` would fire 60 s later. [verified]

**Implication:** the plugin needs a fallback for interrupts. Options:
- When the user sends `<Esc>` / `<C-c>` into a session's terminal, mark it idle.
- Treat `Notification(idle_prompt)` as idle.
- Watch the terminal buffer for the "Interrupted" line.

Registering `PostToolUseFailure` may cover some of these cases; it was not tested.

## 2. Supplying hooks per process: `claude --settings`

- `claude --help` (v2.1.310): `--settings <file-or-json>  Path to a settings JSON file or a JSON string to load additional settings from`.
- CLI reference ([code.claude.com/docs/en/cli-reference][cli]): "Values you set here override the
  same keys in your `settings.json` files for this session. Keys you omit keep their file-based
  values. The file must be a regular file no larger than 2 MiB."
- Settings precedence ([code.claude.com/docs/en/settings][settings]): managed > **command line
  (`--settings`)** > project local > shared project > user. "It can set any key your user settings
  file can set." `--settings` is session-only and writes no file.
- **Merge vs replace:** "When you set the same list key ... in more than one file, Claude Code
  combines the lists instead of picking one" ([settings], "Lists merge instead of overriding"). The
  hooks reference says hook entries merge across levels, and that "A handler defined identically in
  several settings files runs once" ([hooks]).
  - **[verified]:** a `Stop` hook in `proj/.claude/settings.local.json` and a `Stop` hook from
    `--settings` **both** fired for the same Stop.
  - So the user's global hooks keep working, and ours are added on top.
- **Ways to lose our hooks:**
  - `disableAllHooks: true` set at any applicable level. The docs show `--settings '{"disableAllHooks": true}'`.
  - Managed `allowManagedHooksOnly`, which blocks user, project, local and plugin hooks. It is not
    explicit about `--settings` hooks; presumably they are blocked too.
- `--setting-sources user,project,local` restricts which *file* sources load. `--settings` still
  applies. With `--setting-sources ''`, our hooks ran alone [verified].
- An inline JSON string works too. A file is easier, because the hook command needs quoting.
- Settings files are watched and hook edits reload live ([settings], "When edits take effect").
  Editing our generated file mid-session presumably applies too; this was not verified.

## 3. Hook execution environment, `$NVIM`, and calling back into nvim

### Environment

- [hooks]: hooks "inherit the parent environment". The exceptions are that `OTEL_*` exporter
  variables are removed, more variables are stripped with `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1`, and
  Anthropic credentials are removed in HIPAA sessions.
- Claude adds `CLAUDE_PROJECT_DIR`, `CLAUDE_EFFORT`, plugin variables, and `CLAUDE_ENV_FILE` (the
  last only for SessionStart, Setup, CwdChanged and FileChanged).
- **[verified]** The hook environment contained `NVIM=<socket of the nvim that ran jobstart>`, plus
  `CLAUDE_PROJECT_DIR`, `CLAUDE_PID`, `CLAUDE_CODE_SESSION_ID` and `CLAUDECODE=1`.
- Neovim docs (`:help $NVIM`, `runtime/doc/vvars.txt`): "$NVIM is set to v:servername by |terminal|
  and |jobstart()|, and is thus a hint that the current environment is a child (direct subprocess)
  of Nvim."
- **Plugin tip:** don't rely on `$NVIM` alone. Pass your own variables through `jobstart({env=...})`,
  such as `NVIM_CLAUDE_ID=<plugin session id>`, so the hook can say which buffer or session it
  belongs to without mapping `session_id` back. `session_id` changes on `/clear` and resume.

### Calling back

- Neovim docs (`:help --remote-expr`, `runtime/doc/remote.txt`): `--server {addr}` connects to the
  socket. `--remote-expr {expr}` means "Evaluate {expr} in server and print the result on stdout."
- `--remote-wait*` is not supported in Nvim (`:help clientserver-missing`), but it isn't needed here.
- **[verified]** This hook command worked:

  ```sh
  nvim --server "$NVIM" --remote-expr "luaeval('ClaudeHook(_A[1],_A[2])', ['$ev', '$ts'])"
  ```

  The global Lua function ran in the owning nvim, and the return value was printed on stdout.
- **Latency:** about 40 ms from hook start to the function running in nvim, and that included
  spawning `python3` to parse JSON. A bare `nvim --server ... --remote-expr '1+1'` round trip took
  only a few ms.
- **Recommended shape:** forward the whole stdin JSON instead of parsing it in shell. For example:

  ```sh
  payload=$(cat); nvim --server "$NVIM" --remote-expr "luaeval('require(\"claude_sessions\").on_hook(_A[1], _A[2])', [\"$NVIM_CLAUDE_ID\", '$(printf %s "$payload" | base64 -w0)'])" >/dev/null 2>&1 || true
  ```

  Base64 sidesteps quoting, and the plugin decodes it with `vim.base64.decode` + `vim.json.decode`.
  An alternative is a tiny `nvim -l` script, or `--remote-send`, though `--remote-send` is
  mode-sensitive and best avoided.
- **Failure:** `nvim --server /bad.sock --remote-expr 1+1` printed `E247: Failed to connect ...`
  and **exited 2** [verified]. Claude treats exit 2 as a blocking error ([hooks], "Exit codes"):
  - On `PreToolUse` it would block the tool call.
  - On `Stop` it would prevent Claude from stopping.
  - On `UserPromptSubmit` it would reject the prompt.

  **Always `|| true` and `exit 0`.** This can happen if nvim quits while a detached claude keeps
  running.

### stdin JSON

These are the common fields ([hooks], "Common input fields"), and all were seen live:

- `session_id`
- `transcript_path`
- `cwd`
- `hook_event_name`
- `prompt_id`
- `permission_mode` (absent on Notification, SessionStart and SessionEnd)
- `effort`
- `scratchpad_dir`
- `agent_id` and `agent_type` (inside subagents)

Event-specific fields (verified unless noted):

| Event | Extra fields |
|---|---|
| `SessionStart` | `source` (`startup`...), `model` (optional) |
| `UserPromptSubmit` | `prompt` (`session_title` if set) |
| `PreToolUse` | `tool_name`, `tool_input`, `tool_use_id` |
| `PermissionRequest` | `tool_name`, `tool_input`, `permission_suggestions` (no `tool_use_id`) |
| `PostToolUse` | `tool_name`, `tool_input`, `tool_response`, `tool_use_id`, `duration_ms` |
| `Notification` | `message`, `notification_type`, `title` (optional) |
| `Stop` | `stop_hook_active`, `last_assistant_message`, `background_tasks`, `session_crons` |
| `SubagentStop` | as Stop, plus `agent_id`, `agent_type`, `agent_transcript_path` |
| `StopFailure` | `error`, `error_details`, `last_assistant_message` (from the docs) |
| `SessionEnd` | `reason` (`other` when the terminal job was killed with `jobstop`) |

Samples (trimmed, from the experiment):

```json
{"session_id":"b29e54bd-...","cwd":".../proj","hook_event_name":"Notification","message":"Claude needs your permission","notification_type":"permission_prompt"}
{"session_id":"b29e54bd-...","cwd":".../proj","hook_event_name":"Notification","message":"Claude is waiting for your input","notification_type":"idle_prompt"}
{"session_id":"b29e54bd-...","hook_event_name":"PermissionRequest","permission_mode":"default","tool_name":"AskUserQuestion","tool_input":{...}}
{"session_id":"5a71b734-...","hook_event_name":"SessionEnd","reason":"other"}
```

## 4. Gotchas: timeouts, blocking, failures, latency

- **Hooks block by default.** "By default, hooks block Claude's execution until they complete"
  ([hooks], "Run hooks in the background"). `UserPromptSubmit` "block[s] model processing until
  they finish, so a stuck hook stalls the session."
- **Default timeouts** ([hooks]):
  - 600 s for command hooks.
  - 30 s on `UserPromptSubmit`, `PreModelSwitch` and `PostModelSwitch`.
  - `SessionEnd` has a 1.5 s budget, raisable up to 60 s with a per-hook `timeout`.

  Set `"timeout": 2` or similar on every state hook.
- **Timeout behaviour [verified]:** a `UserPromptSubmit` hook doing `sleep 4` with `"timeout": 2`
  was killed; its trailing `echo` never ran. Claude printed `UserPromptSubmit hook [...] timed out
  after 2s — output discarded` into the transcript, and the prompt still went through. The docs
  agree: timed-out hooks are canceled and the action proceeds, unless `"onFailure": "block"` is set
  (v2.1.295+).
- **`"async": true`** (command hooks only) runs the hook in the background, and Claude doesn't wait.
  Timeout is *not* enforced for async hooks. They can't block or decide anything, and their output
  is delivered on the next turn. Async completion notices are hidden unless `--verbose`. In `-p`
  mode, async hooks still running at teardown are killed ([hooks]).
  - [verified] An async `Stop` hook started immediately, while a sibling synchronous `Stop` hook
    ran its full 3 s. Matching hooks run in parallel ([hooks]). An async hook exiting 1 produced
    no visible error.
  - **Recommendation:** use `async: true` for all pure-notification state hooks. You would
    synchronously need only `PermissionRequest` if you wanted nvim to answer permissions, which is
    out of scope. Async state hooks never add latency to Claude.
  - **Caveat:** async hooks may complete out of order. Order events by a timestamp taken at the
    start of the hook, or by event type priority, not by arrival time.
- **Exit codes** ([hooks]):
  - 0: success.
  - 2: blocking error on events that can block.
  - Any other code: non-blocking error. A `<hook name> hook error` notice shows the first line of
    stderr.

  Redirect `nvim`'s stdout and stderr to `/dev/null` and `exit 0` so that nothing leaks into the
  terminal UI.
- **Identical handlers dedupe:** a handler defined identically in several settings files runs once
  ([hooks]). This is harmless here.
- **`SubagentStop` noise:** it fires after `Stop` for internal agents with `agent_type: ""`
  [verified]. Don't treat it as top-level state.
- **`UserPromptSubmit` isn't only typed prompts:** it also fires for `/loop` iterations, background
  subagent reports and messages from other sessions ([hooks]). That is still correctly "working".
- **Background tasks:** `Stop` carries `background_tasks` / `session_crons`, so the plugin can tell
  "done" apart from "paused, will wake itself" ([hooks], Stop input).
- **Debug** with `claude --debug`, which logs hook execution ([hooks], "Debug hooks").
- **Experiment artifact (not a plugin concern):** the test nvim was launched from inside a Claude
  Code session, so it inherited `CLAUDE_CODE_CHILD_SESSION=1`, and the child claude showed
  "Transcript saving is off". The same inherited environment broke `claude -p` auth with "Invalid
  API key". A real nvim started from a normal shell won't have these variables. If the plugin may
  run inside an nvim that was itself spawned by Claude Code, consider clearing `CLAUDECODE*` and
  `CLAUDE_CODE_*` in `jobstart({env=..., clear_env=...})`.

## Suggested `--settings` file (sketch)

The plugin writes this once to `stdpath('cache')/claude-sessions/hooks.json` and launches
`jobstart({'claude', '--settings', path}, {term=true, env={NVIM_CLAUDE_ID=id}})`.

```json
{
  "hooks": {
    "SessionStart":      [{"hooks": [{"type": "command", "command": "<plugin>/hook.sh", "async": true}]}],
    "UserPromptSubmit":  [{"hooks": [{"type": "command", "command": "<plugin>/hook.sh", "async": true}]}],
    "PreToolUse":        [{"hooks": [{"type": "command", "command": "<plugin>/hook.sh", "async": true}]}],
    "PostToolUse":       [{"hooks": [{"type": "command", "command": "<plugin>/hook.sh", "async": true}]}],
    "PermissionRequest": [{"hooks": [{"type": "command", "command": "<plugin>/hook.sh", "async": true}]}],
    "Notification":      [{"hooks": [{"type": "command", "command": "<plugin>/hook.sh", "async": true}]}],
    "Stop":              [{"hooks": [{"type": "command", "command": "<plugin>/hook.sh", "async": true}]}],
    "StopFailure":       [{"hooks": [{"type": "command", "command": "<plugin>/hook.sh", "async": true}]}],
    "SessionEnd":        [{"hooks": [{"type": "command", "command": "<plugin>/hook.sh", "timeout": 2}]}]
  }
}
```

`hook.sh` is `[ -n "$NVIM" ] && nvim --server "$NVIM" --remote-expr "..." >/dev/null 2>&1; exit 0`.

Two parts are untested:
- Whether an async `PermissionRequest` hook still lets the normal dialog show. It should, because
  async hooks can't decide anything.
- Whether async `SessionEnd` survives teardown, which is why the sketch keeps it synchronous with a
  short timeout.

## Experiment (reproducible)

Everything ran in a scratch directory. `~/.claude/settings.json` was read (it has no hooks) but not
modified.

1. Started `nvim --headless --clean --listen <scratch>/nvim.sock -u rpc.lua`. `rpc.lua` defines a
   global `ClaudeHook(ev, ts)` that appends to a log.
2. Through `--remote-expr`, ran `jobstart({'claude','--settings',hooks.json,'--permission-mode','default'}, {term=true, cwd=proj})`
   inside that nvim, so nvim itself set `$NVIM`.
3. `hooks.json` registered `hook.sh` for 10 events. `hook.sh` appends stdin JSON, a timestamp and
   `$NVIM` to `events.jsonl`, dumps `env`, and calls
   `nvim --server "$NVIM" --remote-expr "luaeval('ClaudeHook(...)')"`.
4. `proj/.claude/settings.local.json` registered a second `Stop` hook to test merging.
5. Drove the TUI with `chansend()`: accepted the trust dialog, sent prompts, approved, rejected
   (Esc), answered an `AskUserQuestion`, and waited for `idle_prompt`.
6. Ran a second session with `--setting-sources '' --settings slow.json` to test timeout and async
   behaviour.

## Sources

- [hooks]: Claude Code hooks reference: https://code.claude.com/docs/en/hooks (sections: hook
  events table, Common input fields, Notification, PermissionRequest, Stop, StopFailure,
  SubagentStop, SessionStart, SessionEnd, Exit codes, Run hooks in the background, environment
  variables)
- [settings]: Claude Code settings: https://code.claude.com/docs/en/settings (Settings precedence,
  Lists merge instead of overriding, Change a setting for one session, When edits take effect)
- [cli]: Claude Code CLI reference: https://code.claude.com/docs/en/cli-reference (`--settings`,
  `--setting-sources`)
- `claude --help`, Claude Code 2.1.310 (local)
- Neovim 0.11.7 runtime docs (local): `runtime/doc/vvars.txt` (`*$NVIM*`) and
  `runtime/doc/remote.txt` (`*--server*`, `*--remote-expr*`, `*clientserver-missing*`)
- Local experiment, 2026-10-24, described above

[hooks]: https://code.claude.com/docs/en/hooks
[settings]: https://code.claude.com/docs/en/settings
[cli]: https://code.claude.com/docs/en/cli-reference
