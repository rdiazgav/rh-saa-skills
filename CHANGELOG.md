# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0] - 2026-10-09

Fork of [juanlu-sanz/rh-saa-skills](https://github.com/juanlu-sanz/rh-saa-skills) 1.0.0.
Major version because generated workshops now require Antora 3.

### Added

- Claude Code subagents in `agents/antora-workshop/` (11 `workshop-*` agents with per-agent
  model and effort), linked by `install.sh` into `~/.claude/agents/`.
- `antora-workshop`: Workflow (context, execute with timing, Reset validation, render
  checks), Topology (single cluster vs multi-cluster), OpenShift Local (CRC) notes,
  Resolving Placeholders, RBAC and Least Privilege, Troubleshooting Rules, Demo-friendly
  timing, and Claude Code subagents sections.
- `reference.md`: `scripts/check-site.sh` post-build check, UBI-based Dockerfile,
  supplemental-ui contents, single-cluster `_attributes.adoc` and `myenv.sh`, RBAC verify
  snippet, CLAUDE.md orchestration section, optional `@asciidoctor/tabs` setup.
- Lint: subagent frontmatter validation and em/en dash check; `install.sh` syntax check.
- Release: agents zip per group.

### Changed

- Antora 2.3 replaced by Antora 3 (`@antora/cli` + `@antora/site-generator`). Antora 2.x
  ships `asciidoctor.js` 1.5.9, which ignores `[%collapsible]`.
- `package.json` template: Antora 3 dev dependencies and npm scripts (`build`, `dev`,
  `watch`, `check`) instead of Gulp + Babel.
- CI template: `npm ci` + check script before deploy, instead of
  `kameshsampath/antora-site-action@master`.
- `.gitignore` template no longer ignores `package-lock.json`.
- Pages use `--context {context}` attributes; Reset blocks substitute attributes.
- `install.sh` creates missing `skills/` and `agents/` directories instead of skipping the tool.
- Skill description shortened to stay under the 500-character lint recommendation.

### Fixed

- Em dash rule pointed at a regular hyphen; it now names the character (U+2014).
- Em dashes removed from the skill text itself.
- `00-setup.adoc` sub-steps (including split sub-steps) require their own Verify blocks.
- `index.adoc` template no longer sets `:page-layout: home`, which `rhd-tutorial-ui` lacks.

### Removed

- Dependency on the external `multi-cluster-app-distribution-demo` reference repository.
- `gulpfile.babel.js`, `lib/tab-block.js` and `lib/remote-include-processor.js` from the
  generated structure.

## [1.0.0] - 2026-10-08

### Added

- `antora-workshop` skill: generates structured Red Hat Scholars courseware
  workshops using AsciiDoc and Antora.

### Changed

- Restructured repository from Claude Code marketplace format to a shared
  skills repo for both Cursor and Claude Code.
- Removed personal path references from skill files.
- Made screenshot capture instructions tool-neutral with a Cursor-specific
  example block.

### Removed

- Old `plugins/` directory (openshift-poc and ansible-poc Claude Code plugins).
  These are preserved in the `legacy-plugins` tag.
- `.claude-plugin/marketplace.json`.
