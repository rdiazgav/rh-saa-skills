# rh-saa-skills

Shared AI skills for Red Hat Adoption Architects. Works with both
[Cursor](https://cursor.com) and [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

> This is a fork of [juanlu-sanz/rh-saa-skills](https://github.com/juanlu-sanz/rh-saa-skills)
> by Juanlu Sanz, who created the `antora-workshop` skill. This fork adds the changes
> listed under [What this fork changes](#what-this-fork-changes), learned from building
> and publishing a real workshop with the skill. All credit for the original design goes
> to the upstream author.

## Available Skills

| Skill | Description |
|---|---|
| **antora-workshop** | Generates structured Red Hat Scholars courseware workshops using AsciiDoc and Antora 3, with progressive hands-on steps, collapsible verification blocks, and reset/undo sections. Single-cluster (OpenShift Local / CRC, SNO) or multi-cluster |

## Claude Code Subagents (optional)

`agents/antora-workshop/` contains 11 subagents that split the workshop work by role, each
with its own model and effort level (Opus for design, diagnosis and review; Sonnet for
writing and execution; Haiku for mechanical sweeps). Cursor ignores them.

| Agent | Model | Role |
|---|---|---|
| `workshop-docs-researcher` | Sonnet | Verifies product facts against official docs |
| `workshop-architect` | Opus | Topology, RBAC, endpoints, least privilege |
| `workshop-manifest-writer` | Sonnet | YAML manifests, dry-run validated |
| `workshop-module-writer` | Sonnet | AsciiDoc pages |
| `workshop-executor` | Sonnet | Runs steps with timing; never diagnoses |
| `workshop-troubleshooter` | Opus | Root cause of failures |
| `workshop-reset-validator` | Sonnet | Reset + clean re-run |
| `workshop-reviewer` | Opus | Cross-checks reports, pages and manifests |
| `workshop-sweeper` | Haiku | Placeholders, broken xrefs, convention greps |
| `workshop-style-editor` | Sonnet | Final prose pass (uses the `humanizer` skill if installed) |
| `workshop-publisher` | Sonnet | Build, checks, CI, GitHub Pages |

Recommended main session: `claude --model opusplan` (Opus while planning, Sonnet while
executing). Check which model each running subagent uses with `/tasks`.

## Install

### First time

Clone the repository and run the install script:

```bash
git clone https://github.com/rdiazgav/rh-saa-skills ~/.rh-saa-skills
~/.rh-saa-skills/install.sh
```

The script creates symlinks into `~/.cursor/skills/` and `~/.claude/skills/`, and links the
subagents into `~/.claude/agents/`. A tool is skipped only if its home directory
(`~/.cursor` or `~/.claude`) does not exist; missing `skills/` or `agents/` subdirectories
are created. Because these are symlinks, both tools always read the same files.

Restart any running Claude Code session after installing so it loads the new agents.

### Update

When there's a new version:

```bash
~/.rh-saa-skills/install.sh update
```

This pulls the latest changes and re-links any new skills and agents that were added.

### Get notified of updates

Set the repository's **Watch** option to **Releases only** on GitHub. You'll
get an email whenever a new version is tagged.

### Windows / Claude Desktop / Claude Web

Download the zips from the
[latest release](https://github.com/rdiazgav/rh-saa-skills/releases/latest)
and extract the skill folder (and, for Claude Code, the agents folder into
`~/.claude/agents/`). Updating means downloading and extracting the new zips.

## How it works

Each skill is a directory under `skills/` containing a `SKILL.md` file (and
optionally supporting files like `reference.md`). Both Cursor and Claude Code
read `SKILL.md` files with the same format: YAML frontmatter with `name` and
`description`, followed by the full instructions.

Claude Code subagents live under `agents/<group>/` as Markdown files with YAML frontmatter
(`name`, `description`, `tools`, `model`, `effort`) followed by the subagent's system prompt.

The `install.sh` script symlinks each skill directory and each agent group into the
locations where Cursor and Claude Code look for them. Since they're symlinks, a
`git pull` in this repo instantly updates every linked tool.

## What this fork changes

Compared to upstream `1.0.0`:

- **Antora 3 instead of Antora 2.** Antora 2.x ships `asciidoctor.js` 1.5.9, which ignores
  `[%collapsible]`, so every verification block rendered as an always-open
  "Example N." block even though the source was correct.
- **Self-contained templates.** Every boilerplate file is in `reference.md`; no external
  reference repository and no legacy `lib/` extensions (Asciidoctor 1.5 API). Optional
  tabs use the official `@asciidoctor/tabs`.
- **Reproducible CI.** `package-lock.json` is committed (it was gitignored), CI uses
  `npm ci` instead of an action that pulls an unpinned Antora, and a post-build check
  (`scripts/check-site.sh`) blocks the deploy if collapsibles do not render, placeholders
  remain, or em dashes appear.
- **Single-cluster support.** Topology section, `{context}` attributes, single-cluster
  `myenv.sh` and `00-setup.adoc` options, and OpenShift Local (CRC) notes (memory/CPU,
  monitoring off by default, scrape interval vs `rate()` windows).
- **Placeholder resolution.** `<github-user>` and friends are resolved from the Git remote
  before the first commit and checked after every build.
- **RBAC and troubleshooting rules.** Least privilege by default, every permission proven
  with `oc auth can-i`, and no "unsupported" conclusion without RBAC and docs evidence.
- **Explicit workflow.** Context gathering in `t/`, end-to-end execution with timing,
  Reset validation with a clean re-run, then render checks and publish.
- **Fixed rules.** The em dash rule had lost its character and pointed at a hyphen;
  `00-setup.adoc` sub-steps now require Verify blocks too; `:page-layout: home` removed
  (not in `rhd-tutorial-ui`).
- **Claude Code subagents** with per-agent model and effort.
- **Tooling.** `install.sh` creates missing `skills/`/`agents/` dirs; lint validates agent
  frontmatter and blocks em/en dashes; release publishes an agents zip.

## Repository Structure

```
rh-saa-skills/
├── skills/
│   └── antora-workshop/
│       ├── SKILL.md              # Skill instructions
│       └── reference.md          # Boilerplate templates
├── agents/
│   └── antora-workshop/          # Claude Code subagents (workshop-*.md)
├── install.sh                    # Install and update script
├── CHANGELOG.md
├── README.md
├── .github/
│   ├── CODEOWNERS
│   ├── ISSUE_TEMPLATE/
│   │   └── skill-misfire.yml     # "The skill did the wrong thing" template
│   └── workflows/
│       ├── lint.yml              # Validates skills, agents and style rules
│       └── release.yml           # Zips skills and agents and attaches to GitHub Releases
```

## Contributing

### Modifying a skill

1. Fork this repository and create a feature branch.
2. Edit the `SKILL.md` and/or supporting files under `skills/<name>/`.
3. Test the skill by running Cursor or Claude Code with the updated files.
4. Open a PR with a clear description of what changed and why. Include a
   sample prompt and summary of the output the AI produces.

### Adding a new skill

1. Create `skills/<skill-name>/SKILL.md` with YAML frontmatter:

   ```markdown
   ---
   name: my-skill
   description: >-
     When and why the AI should activate this skill.
     Be specific about trigger phrases.
   ---

   # Skill Title

   Instructions go here...
   ```

2. Add a supporting file (e.g. `templates.md`, `reference.md`) if the skill
   needs boilerplate templates.
3. Update this README's **Available Skills** table.
4. Open a PR.

### Adding subagents

Create `agents/<group>/<agent-name>.md` with frontmatter on line 1 (`name`, `description`,
and optionally `tools`, `model`, `effort`). Agent names must be unique across all groups.

### Reporting a skill misfire

If a skill triggered when it shouldn't have, or produced the wrong output,
[open an issue](https://github.com/rdiazgav/rh-saa-skills/issues/new?template=skill-misfire.yml)
with the prompt you used, what happened, and what you expected.

## Authors

- Juanlu Sanz - original author of the repository and the `antora-workshop` skill
  ([upstream](https://github.com/juanlu-sanz/rh-saa-skills))
- Roberto Diaz ([@rdiazgav](https://github.com/rdiazgav)) - fork maintainer

## License

Apache-2.0
