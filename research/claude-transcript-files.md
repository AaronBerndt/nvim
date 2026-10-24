# How do we locate and read a Session's Transcript?

Research ticket for the nvim Claude-sessions plugin. Researched 2026-10-24 against
Claude Code **v2.1.310** (`claude --version`), official docs at code.claude.com, and
empirical inspection of `~/.claude/` on this machine (38 transcripts, ~45k records,
plus controlled tmux experiments). Conversation content is never quoted below; only
structure, field names and redacted values.

## Answer

- **Location:** `~/.claude/projects/<project>/<session-id>.jsonl`, where `<project>` is the
  session's **launch cwd with every non-alphanumeric character replaced by `-`**
  (`/home/aaron/.config/nvim` -> `-home-aaron--config-nvim`). Names over 200 chars are
  truncated to 200 and get a hash of the full path appended. `CLAUDE_CONFIG_DIR` moves
  the root; `CLAUDE_CODE_PROJECT_DIR_NAME` overrides `<project>`. [D1] [E1]
- **Pin the id:** yes. `claude --session-id <uuid>` makes the file
  `<uuid>.jsonl`. Reusing an id that already has a transcript fails with
  `Error: Session ID <uuid> is already in use.` [H] [E2]
- **Id changes:** `/clear` -> **new id and new file**, same process. Nothing in the new file
  points back to the old one. `/compact` (auto or manual) -> **same id, same file**; a
  `system/compact_boundary` record is appended. `--resume`/`--continue` -> **same id, appends
  to the same file**. `--fork-session` / `/branch` -> **new id, new file** holding a copy
  of the history with `sessionId` rewritten. [D2] [D3] [E2] [E3] [E5]
- **Tracking the current id of a running process:** `~/.claude/sessions/<pid>.json` holds
  `{pid, sessionId, cwd, status, waitingFor, ...}` and is updated in place on `/clear`.
  Since the plugin knows each terminal job's PID, this is the most reliable
  pid -> transcript mapping. It is undocumented beyond "one small file per running
  session". [D1] [E5]
- **Schema:** one JSON object per line. Conversation records (`user`, `assistant`,
  `system`, `attachment`) form a tree via `uuid`/`parentUuid`. They are interleaved with
  many metadata record types (`mode`, `permission-mode`, `last-prompt`, `ai-title`,
  `api-request*`, `file-history-*`, `queue-operation`, `cost-state`, ...). **Each assistant
  content block is its own record** (shared `message.id`, distinct `apiBlockIndex`). Tool
  results are `user` records carrying `tool_result` blocks. There is no top-level
  `tool_use`/`tool_result`/`summary` record type in current versions. Anthropic states the format is
  **internal and changes between versions**. [D2] [E4]
- **Live/tailable:** yes, appended continuously (records land within about a second). But
  writes are async, and **an assistant turn that is blocked on a permission prompt or an
  AskUserQuestion dialog is not on disk until the user answers**. [D4] [E6]
- **State inference:** *idle* and *working* can be inferred from the transcript tail
  (skip metadata records first). *Waiting-on-user* **cannot** be: while a dialog is open
  the tail looks the same as "request in flight". Use `~/.claude/sessions/<pid>.json`
  `status` (`busy` | `idle` | `waiting` + `waitingFor: "permission prompt"` /
  `"input needed"` / `"dialog open"`), or hooks (`Notification` matchers
  `permission_prompt` / `idle_prompt`, `Stop`) for state. Use the transcript for content. [D4] [E5] [E6]

## Sources

- **[D1]** Docs, *Explore the .claude directory*: Application data:
  https://code.claude.com/docs/en/claude-directory#application-data
- **[D2]** Docs, *Manage sessions*: "Where transcripts are stored", "Branch a session",
  "Manage context within a session": https://code.claude.com/docs/en/sessions
- **[D3]** Docs, *How Claude Code works*: "Resume or fork sessions":
  https://code.claude.com/docs/en/how-claude-code-works#resume-or-fork-sessions
- **[D4]** Docs, *Hooks reference*: common input fields (`transcript_path`), SessionStart
  sources, Notification matchers: https://code.claude.com/docs/en/hooks
- **[H]** `claude --help` (v2.1.310), local.
- **[E1]-[E6]** Empirical observations on this machine, detailed below.

## 1. Location and cwd encoding

Docs [D2]: *"By default, Claude Code stores transcripts as JSONL at
`~/.claude/projects/<project>/<session-id>.jsonl`, where `<project>` is your working
directory path with non-alphanumeric characters replaced by `-`. For a working directory
whose converted name exceeds 200 characters, Claude Code truncates the name to 200
characters and appends a hash of the full path."* [D1] describes the same rule for the
scratchpad `<project>` segment ("every character other than letters and digits replaced
by `-`").

**[E1] Verified:**

| cwd | directory |
|---|---|
| `/home/aaron/.config/nvim` | `-home-aaron--config-nvim` (`/` and `.` both become `-`, so `/.` gives `--`) |
| `/home/aaron/gitstuff/4e-pwa/.claude/worktrees/dddice` | `-home-aaron-gitstuff-4e-pwa--claude-worktrees-dddice` |
| `/tmp/.../scratchpad/enc_test.dir_x y@z` (test) | `...-scratchpad-enc-test-dir-x-y-z` (`_`, `.`, space and `@` all become `-`) |

Lua equivalent: `cwd:gsub("[^%w]", "-")`. Note that `%w` is locale-dependent for non-ASCII.
To be safe, treat non-ASCII paths as "glob and verify via the `cwd` field" (see below). The mapping
is **lossy**, so it is not reversible: use the `cwd` field inside records to recover the
real path.

Caveats:
- The directory comes from the cwd **at launch**. `/cd` relocates the session into the new
  directory's storage [D2]. A `relocated` record type (`relocatedCwd`) was seen in the data.
- `claude --resume <id>` searches all projects [D2], so a resumed session may live under
  another project directory than the current cwd suggests.
- Other files under `projects/<project>/` [D1]: `<session>/subagents/agent-<id>.jsonl`
  (+ `.meta.json`), `<session>/tool-results/` (large tool outputs spilled to files),
  `<session>.orphaned-*.jsonl` / `<session>.jsonl.superseded-*` (set-aside copies),
  `memory/` (auto memory). Retention is `cleanupPeriodDays`, 30 days by default.
- **Subagent transcripts** are stored under the *parent's* session dir even when the
  subagent runs in a different cwd (e.g. a worktree). Records have `isSidechain: true`,
  `agentId`, and the parent's `sessionId`. [E4]

## 2. Pinning and session-id lifecycle

From `claude --help` [H]:
- `--session-id <uuid>`: "Use a specific session ID for the conversation (must be a valid UUID)"
- `-r, --resume [value]`: resume by session ID or name (or picker). Docs also allow a
  `.jsonl` path [D2].
- `-c, --continue`: most recent conversation in the cwd
- `--fork-session`: "When resuming, create a new session ID instead of reusing the original"
- `-n, --name <name>`: display name (shown in `/resume` picker and terminal title)
- `--no-session-persistence`: no transcript (only with `-p`)

**[E2] Experiment** (`claude -p --session-id 11111111-2222-4333-8444-555555555555`, odd-named dir):
1. File created as `11111111-2222-4333-8444-555555555555.jsonl`. It was written even though
   the API call failed.
2. Same `--session-id` again: `Error: Session ID ... is already in use.` (exit, nothing written).
3. `--resume <that id>`: new records appended **to the same file**, same `sessionId`.
4. `--resume <id> --fork-session`: **new file** `<new-uuid>.jsonl` containing the full prior
   history, every record's `sessionId` rewritten to the new id. The original file is unchanged.
5. `--continue`: appended to the most recently used session (here, the fork).

Docs agree [D3]: *"Resuming a session with `claude --continue` or `claude --resume`
reopens it under the same session ID and appends new messages ... Forking with
`--fork-session` or `/branch` copies the history into a new session ID."*

**`/clear`:** docs [D2]: *"start fresh with an empty context. Claude Code saves the
previous session; resume it with `/resume`..."*. The SessionStart hook fires with source
`clear` [D4]. **[E5] Verified interactively** (tmux): after `/clear`, the same PID's
registry entry switched `sessionId` from `4d0f3e67…` to `4a8c269c…`, and a new
`4a8c269c….jsonl` appeared. Its first records were `mode`, `file-history-snapshot`, a meta
`user` record, a `user` record holding the `/clear` command, and
`system/local_command` with `commandRun: {command: "clear"}`. Every record had
`parentUuid: null` at the root. **No field references the previous session id.**

**`/compact`:** **[E3]** all 10 compactions found locally stayed in the same file with the same
`sessionId` (every file had exactly one `sessionId`). Compaction appends a
`system` record with `subtype: "compact_boundary"`, `content: "Conversation compacted"`,
`parentUuid: null`, `logicalParentUuid: <last pre-compact uuid>`, and `compactMetadata`
(`trigger: "auto"|"manual"`, `preTokens`, `postTokens`, `preservedSegment`, ...). It is
followed by a `user` record with `isCompactSummary: true` (string content = the summary). Pre-compact
records stay in the file, so a buffer view can show the whole history.

**Implication for the plugin:** pinning `--session-id` at spawn gives the initial path
for free. After a `/clear`, though, that id is stale. Re-resolve via
`~/.claude/sessions/<pid>.json` (or a SessionStart hook that reports `session_id` +
`transcript_path`, which hooks receive as input [D4]).

## 3. Record schema (as observed in v2.1.2xx–2.1.310)

> "Each line is a JSON object for a message, tool use, or metadata entry. The entry
> format is internal to Claude Code and changes between versions, so scripts that parse
> these files directly can break on any release." [D2]

**[E4]** Type census across 38 local transcripts:

| `type` | role | notes |
|---|---|---|
| `user` | conversation | Human prompt (`message.content` string, or `[text, image]` blocks), **or** tool results (`[tool_result]` blocks), or meta/injected (`isMeta: true`) |
| `assistant` | conversation | **One record per content block**: `thinking`, `text`, or `tool_use`. Blocks of the same API response share `message.id`, `requestId`, and `stop_reason`; `apiBlockIndex` orders them |
| `system` | conversation | `subtype`: `turn_duration` (end of turn; `durationMs`, `messageCount`), `compact_boundary`, `local_command` (slash commands), `informational`, `away_summary` |
| `attachment` | conversation | Injected context. `attachment.type`: e.g. `environment`, `date`, `file`, `edited_text_file`, `queued_command`, `skill_listing`, `total_tokens_reminder`, `prompt_snapshot`, ... |
| `queue-operation` | meta | `operation: enqueue|dequeue|remove` for messages typed while Claude works |
| `mode`, `permission-mode`, `atis-latch` | meta | Current mode, e.g. `permissionMode: auto|default|acceptEdits|plan` |
| `last-prompt` | meta | `lastPrompt`, `leafUuid` (current leaf of the tree) |
| `ai-title` | meta | `aiTitle`: generated session title, handy for buffer names |
| `api-request`, `api-request-blob`, `api-request-shape` | meta | Request bookkeeping; `api-request-blob.message` duplicates content. **Skip these when rendering** |
| `file-history-snapshot`, `file-history-delta` | meta | Checkpoint data |
| `cost-state` | meta | `totalCostUSD`, durations, `modelUsage` |
| `worktree-state`, `relocated`, `frame-link`, `artifact-*` | meta | Feature-specific |

No `summary` or top-level `tool_use`/`tool_result` record types were found in any local file
(older Claude Code versions used `type: "summary"` records; current versions don't).

**Common envelope** on conversation records (`user`/`assistant`/`system`/`attachment`):
`uuid`, `parentUuid` (null at roots), `isSidechain`, `timestamp` (ISO-8601 UTC),
`sessionId`, `cwd`, `gitBranch`, `version`, `userType`, `entrypoint`, optional `slug`,
`isMeta`. Metadata records usually carry only `type`, `sessionId`, and their payload, often
with no `uuid` or `timestamp`.

**Assistant record** (redacted):
```json
{"type":"assistant","uuid":"…","parentUuid":"…","timestamp":"…","sessionId":"…","cwd":"…",
 "requestId":"req_…","apiBlockIndex":1,
 "message":{"id":"msg_…","role":"assistant","model":"…","stop_reason":"tool_use",
   "content":[{"type":"tool_use","id":"toolu_…","name":"Bash","input":{…}}],
   "usage":{…}}}
```
`stop_reason` values seen: `tool_use`, `end_turn`, `stop_sequence`, null (synthetic error
records have `isApiErrorMessage: true`).

**Tool result record** (redacted):
```json
{"type":"user","uuid":"…","parentUuid":"<uuid of the assistant tool_use record>",
 "sourceToolAssistantUUID":"…","toolUseResult":{…},
 "permissionDecision":{"decision":"accept","source":"config","reasonType":"classifier"},
 "message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"toolu_…",
   "content":"…","is_error":false}]}}
```
`permissionDecision.source` shows *after the fact* who approved: `config` (rules,
mode, or classifier), `user_temporary` (user clicked yes), or `user_reject`. A user rejection
also sets `toolDenialKind: "user-rejected"` with `is_error: true`, then a `user` text
`[Request interrupted by user for tool use]`.

**Rendering notes:** follow `parentUuid` from `last-prompt.leafUuid` (or simply file order
for the main thread). Group assistant records by `message.id`. Pair `tool_use.id` with
`tool_result.tool_use_id`. Drop `isMeta`, `attachment`, and all metadata types for a readable
buffer. Large outputs may be in `<session>/tool-results/<toolu_id>.txt`.

**Tailing notes:** 2 of ~45k lines failed to parse in a snapshot of live files, i.e. a
partially written final line. A tailer must buffer until `\n`.

## 4. Inferring working / waiting / idle

**Is it appended live?** Yes. **[E6]** In this agent's own transcript, `assistant tool_use`
records appeared on disk before the tool's `tool_result`, within about a second. But docs warn
[D4]: *"The transcript file is written asynchronously and may lag the in-memory
conversation."*

**Controlled experiments [E6]** (interactive `claude` in tmux, watching both the transcript
and `~/.claude/sessions/<pid>.json`):

| Situation | Transcript tail (after skipping metadata types) | Registry `status` / `waitingFor` |
|---|---|---|
| Prompt submitted, model thinking/streaming | `user` (prompt string) + `attachment`s, then `api-request` | `busy` |
| **AskUserQuestion dialog open** (watched for 40 s+) | **unchanged: no assistant record at all**. The `tool_use` (timestamp 13:43:40) was only written at 13:44:22 together with its `tool_result`, after the answer | `waiting` / `input needed` |
| **Bash permission prompt open** (manual mode) | **unchanged: no assistant record** | `waiting` / `permission prompt` |
| Tool approved and running (perl, 25 s wait) | `assistant tool_use` with **no matching `tool_result`** | `busy` |
| Turn finished | `assistant text` (`stop_reason: end_turn`) then **`system` `subtype: turn_duration`** | `idle` |
| User rejected the tool | `tool_result is_error` + `toolDenialKind`, `user` "[Request interrupted…]", `system/turn_duration` | `idle` |

Historical data agrees: `system/turn_duration` immediately followed `assistant text
stop=end_turn` in 292/299 cases (the rest: interruptions). For AskUserQuestion answers,
`tool_result.timestamp - tool_use.timestamp` was 22–783 s. That is the wait time, but it is
only visible after the fact.

**Conclusion:**
- *Idle*: last conversation record is `system/turn_duration` (reliable).
- *Working*: last conversation record is a `user` prompt, a `tool_result`, or an
  `assistant tool_use` without a result.
- *Waiting on user*: **not observable from the transcript.** It looks the same as
  "API request in flight". A heuristic like "busy-looking tail and no growth for N seconds"
  would misfire on long model thinking and long-running tools.
- Also present in the registry: `waiting` / `dialog open` was seen on another session.

**Recommended state source:** `~/.claude/sessions/<pid>.json`. It is keyed by the PID the plugin
already has from `jobstart`/`termopen`, and gives `sessionId` (follows `/clear`), `cwd`,
`status` (`busy`/`idle`/`waiting`), `waitingFor`, `statusUpdatedAt`, and `name`.
Caveats: it is undocumented except as "one small file per running session, used to detect concurrent
sessions and crashes... removed when its session exits" [D1]. Stale files from crashed
processes linger (older-version entries lacked `status` entirely), so check PID liveness. The
documented alternative is hooks [D4]: `Notification` (`permission_prompt`,
`idle_prompt`, `elicitation_dialog`, `agent_needs_input`), `Stop`, `UserPromptSubmit`,
`SessionStart` (sources `startup|resume|clear|compact|fork`). All of them receive
`session_id` and `transcript_path`.

## Open questions

- The registry file format is undocumented and could change. Whether hooks are worth the
  setup cost as a documented fallback is a design decision for another ticket.
- `/cd` relocation and `--resume` from another directory were read about [D2] but not
  tested. In those cases, always take the path from the registry or hook, not from the
  cwd encoding.
