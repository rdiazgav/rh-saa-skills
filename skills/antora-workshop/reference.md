# Reference Files

Exact boilerplate file contents to copy when creating a new workshop repository.
Adapt placeholders marked with `<...>` to match the new workshop, and resolve all of them
before the first commit (see **Resolving Placeholders** in SKILL.md).

Tested combination: Antora 3.2 (`@antora/cli` + `@antora/site-generator`), Node.js 22,
`rhd-tutorial-ui` v0.1.10.

---

## package.json Template

```json
{
  "name": "<repo-name>",
  "description": "<Workshop Title> - Course Documentation Site",
  "homepage": "https://<github-user>.github.io/<repo-name>",
  "private": true,
  "scripts": {
    "build": "antora --fetch --stacktrace site.yml",
    "build:dev": "antora --stacktrace dev-site.yml",
    "dev": "npm run build:dev && browser-sync start --server gh-pages --files 'gh-pages/**/*' --port 3000 --no-open",
    "watch": "chokidar 'documentation/**/*' -c 'npm run build:dev'",
    "check": "bash scripts/check-site.sh",
    "clean": "rm -rf gh-pages .cache"
  },
  "devDependencies": {
    "@antora/cli": "^3.1.0",
    "@antora/site-generator": "^3.1.0",
    "browser-sync": "^3.0.0",
    "chokidar-cli": "^3.0.0"
  },
  "repository": {
    "type": "git",
    "url": "git+https://github.com/<github-user>/<repo-name>.git"
  },
  "license": "Apache-2.0"
}
```

Run `npm install` once to generate `package-lock.json` and commit it. CI uses `npm ci`,
which installs exactly what the lockfile pins.

Local preview: `npm run dev` in one terminal (serves http://localhost:3000 and reloads
the browser when `gh-pages/` changes) and `npm run watch` in another (rebuilds when
`documentation/` changes).

---

## antora.yml Template

```yaml
name: <workshop-slug>
title: <Workshop Title>
version: master
nav:
  - modules/ROOT/nav.adoc
start_page: ROOT:index.adoc
```

---

## site.yml Template

```yaml
runtime:
  cache_dir: ./.cache/antora

site:
  title: <Workshop Title>
  url: https://<github-user>.github.io/<repo-name>
  start_page: <workshop-slug>::index.adoc

content:
  sources:
    - url: ./
      branches: HEAD
      start_path: documentation

asciidoc:
  attributes:
    release-version: master
    page-pagination: true

ui:
  bundle:
    url: https://github.com/redhat-developer-demos/rhd-tutorial-ui/releases/download/v0.1.10/ui-bundle.zip
    snapshot: true
  supplemental_files:
    - path: ./supplemental-ui
    - path: .nojekyll
    - path: ui.yml
      contents: "static_files: [ .nojekyll ]"

output:
  dir: ./gh-pages
```

---

## dev-site.yml Template

```yaml
runtime:
  cache_dir: ./.cache/antora

site:
  title: <Workshop Title> (Dev Mode)
  url: http://localhost:3000
  start_page: <workshop-slug>::index.adoc

content:
  sources:
    - url: .
      branches: HEAD
      start_path: documentation

asciidoc:
  attributes:
    title: <Workshop Title> (Dev Mode)

ui:
  bundle:
    url: https://github.com/redhat-developer-demos/rhd-tutorial-ui/releases/download/v0.1.10/ui-bundle.zip
    snapshot: true
  supplemental_files: ./supplemental-ui

output:
  dir: ./gh-pages
```

---

## supplemental-ui/

Create these files:

`supplemental-ui/.nojekyll` - empty file (tells GitHub Pages not to run Jekyll).

`supplemental-ui/ui.yml`:

```yaml
static_files: [ .nojekyll ]
```

`supplemental-ui/partials/footer-nav.hbs`:

```hbs
<nav class="rhd-footer-nav" aria-label="Secondary Navigation" role="navigation">
  <ul class="rhd-menu">
    <li class="menu-item menu-item--expanded">
      <h3 class="section-toggle">Resources</h3>
      <ul class="rhd-menu">
        <li class="menu-item">
          <a href="https://<github-user>.github.io/<repo-name>" title="<Workshop Title>">Course
            Site</a>
        </li>
        <li class="menu-item">
          <a href="https://github.com/<github-user>/<repo-name>/issues" title="Issue Tracker">Issue
            Tracker</a>
        </li>
      </ul>
    </li>
  </ul>
</nav>
```

Optional: `supplemental-ui/img/favicon.ico`.

---

## site.sh

```bash
#!/bin/bash
# site.sh
# Purpose: Clean production build of the course site.

_CURR_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
rm -rf "$_CURR_DIR/gh-pages" "$_CURR_DIR/.cache"

npx antora --fetch --stacktrace site.yml
```

---

## scripts/check-site.sh

Run after every build (`npm run check`). CI runs it before deploying.

```bash
#!/usr/bin/env bash
# scripts/check-site.sh
# Purpose: Fail if the built site or its sources break the workshop conventions.
set -uo pipefail

PAGES="documentation/modules/ROOT/pages"
SITE="${SITE_DIR:-gh-pages}"
fail=0

if [ ! -d "$SITE" ]; then
  echo "ERROR: $SITE not found. Run 'npm run build' first."
  exit 1
fi

echo "== Collapsible verification blocks (source vs rendered)"
for f in "$PAGES"/*.adoc; do
  p=$(basename "$f" .adoc)
  case "$p" in _*) continue ;; esac
  html=$(find "$SITE" -name "$p.html" -not -path '*/_/*' | head -1)
  if [ -z "$html" ]; then
    echo "ERROR: no rendered HTML found for $p"
    fail=1
    continue
  fi
  src=$(grep -c '%collapsible' "$f" || true)
  out=$(grep -c '<details' "$html" || true)
  if [ "$src" != "$out" ]; then
    echo "ERROR: $p adoc=$src html=$out (collapsible blocks did not render)"
    fail=1
  else
    echo "OK:    $p collapsible=$src"
  fi
done

echo "== Unresolved template placeholders"
if grep -rnE '<(github-user|repo-name|workshop-slug|Workshop Title|Workshop Tagline)>' \
     --include='*.adoc' --include='*.yml' --include='*.yaml' --include='*.json' \
     --include='*.hbs' --include='*.html' \
     --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=.cache .; then
  echo "ERROR: unresolved placeholders found"
  fail=1
else
  echo "OK"
fi

echo "== Em dashes and en dashes in courseware"
if grep -rn -e $'\xe2\x80\x94' -e $'\xe2\x80\x93' documentation/; then
  echo "ERROR: replace them with a regular hyphen"
  fail=1
else
  echo "OK"
fi

echo "== oc commands without --context (review; multi-line commands may be false positives)"
grep -nE '^\s*oc ' "$PAGES"/*.adoc \
  | grep -v -- '--context' \
  | grep -vE 'oc (login|config|version)' \
  || echo "OK"

exit $fail
```

---

## Dockerfile

Builds the site with the same locked dependencies as CI and serves it with UBI httpd.

```dockerfile
# Dockerfile
# Purpose: Build the Antora site and serve it with httpd (port 8080).

FROM registry.access.redhat.com/ubi9/nodejs-22 AS builder
COPY --chown=1001:0 . /opt/app-root/src
RUN npm ci && npx antora --fetch --stacktrace site.yml

FROM registry.access.redhat.com/ubi9/httpd-24
COPY --from=builder /opt/app-root/src/gh-pages/ /var/www/html/
```

The build context must include `.git`: the playbook reads content from the local Git
repository (`url: ./`).

---

## .github/workflows/docs.yml

```yaml
name: docs

on:
  push:
    branches:
      - main
      - master
  workflow_dispatch:

permissions:
  contents: write

jobs:
  build_and_deploy:
    name: "Build and deploy site"
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Node
        uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm

      - name: Build site with Antora
        run: |
          npm ci
          npx antora --stacktrace site.yml

      - name: Check rendered site and sources
        run: bash scripts/check-site.sh

      - name: Deploy to GitHub Pages
        uses: JamesIves/github-pages-deploy-action@v4
        with:
          folder: gh-pages
          branch: gh-pages
          commit-message: "[CI] Publish Documentation for ${{ github.sha }}"
```

After the first successful run, enable GitHub Pages on the `gh-pages` branch
(Settings > Pages) if it is not enabled yet.

---

## Optional: Tabbed Content

Only if a workshop needs tabs (e.g. the same command for Linux and macOS). Add the official
extension and its assets:

```bash
npm install -D @asciidoctor/tabs
mkdir -p supplemental-ui/css supplemental-ui/js supplemental-ui/partials
cp node_modules/@asciidoctor/tabs/dist/css/tabs.css supplemental-ui/css/
cp node_modules/@asciidoctor/tabs/dist/js/tabs.js supplemental-ui/js/
```

Register it in both playbooks:

```yaml
asciidoc:
  extensions:
    - '@asciidoctor/tabs'
```

Load the CSS and JS from the UI by overriding the bundle's head and footer partials in
`supplemental-ui/partials/`. Partial names depend on the UI bundle: list them with
`unzip -l` on the downloaded bundle before overriding. Build and confirm the tabs render;
this path is untested with `rhd-tutorial-ui`.
Syntax:

```asciidoc
[tabs]
====
Linux::
+
[source,bash]
----
<command>
----

macOS::
+
[source,bash]
----
<command>
----
====
```

---

## _attributes.adoc Template

Single cluster:

```asciidoc
:experimental:
:source-highlighter: highlightjs
:title: <Workshop Title>
:context: crc
:namespace: <workshop-namespace>
:ocp-version: X.Y
:<product-1>-version: X.Y+
```

Multi-cluster:

```asciidoc
:experimental:
:source-highlighter: highlightjs
:title: <Workshop Title>
:hub-context: hub
:cluster-a-context: cluster-a
:cluster-b-context: cluster-b
:ocp-version: X.Y
:<product-1>-version: X.Y+
:<product-2>-version: X.Y+
```

Pages reference contexts as `--context {context}` (or `{hub-context}`, etc.) inside source
blocks that include `subs="+macros,+attributes"`.

---

## index.adoc Template

```asciidoc
= <Workshop Title>
:!sectids:
include::_attributes.adoc[]

[.text-center.strong]
== <Workshop Tagline>

<One-paragraph workshop description.>

[.tiles.browse]
== Browse Modules

[.tile]
.xref:00-setup.adoc[Cluster Setup]
* xref:00-setup.adoc#prerequisites[Prerequisites]
* xref:00-setup.adoc#export-variables[Export Variables]

[.tile]
.xref:01-<step>.adoc[Step 01: <Title>]
* xref:01-<step>.adoc#anchor[Sub-step]

== Environment

[cols="2,3",options="header"]
|===
| Item | Value
| OpenShift version | {ocp-version}
|===
```

---

## nav.adoc Template

```asciidoc
* xref:index.adoc[Overview]
* xref:00-setup.adoc[Cluster Setup]
** xref:00-setup.adoc#prerequisites[Prerequisites]
** xref:00-setup.adoc#export-variables[Export Workshop Variables]
* xref:01-<step>.adoc[Step 01: <Title>]
** xref:01-<step>.adoc#anchor[Sub-step]
* xref:02-<step>.adoc[Step 02: <Title>]
** xref:02-<step>.adoc#anchor[Sub-step]
```

---

## Step Page Template

```asciidoc
= Step N - Title: Descriptive Subtitle
include::_attributes.adoc[]

<One-paragraph description of what this step does, what problem it solves,
and how it builds on the previous step.>

== Prerequisites

* <Prerequisite 1>
* <Previous step> from xref:previous-page.adoc[Step N-1] fully operational
* `oc` CLI authenticated as cluster-admin
* Contexts renamed as described in the xref:00-setup.adoc[Cluster Setup] section

NOTE: <Any important context or assumptions.>

== How It Works

<Brief architectural explanation. Use numbered lists or diagrams.>

== Steps to Apply

[#anchor-1]
=== 1. First sub-step title

*What:* One sentence describing the concrete action.

*Why:* One sentence explaining why this step matters.

[.console-input]
[source,bash,subs="+macros,+attributes"]
----
oc apply -f NN-step/resource.yaml --context {context}
----

.Verify: Description of what to check
[%collapsible]
====
[.console-input]
[source,bash,subs="+macros,+attributes"]
----
oc get <resource> -n {namespace} --context {context}
----

[.console-output]
[source,bash]
----
<expected output from a real run>
----
====

'''

[#anchor-2]
=== 2. Second sub-step title

*What:* ...

*Why:* ...

...

'''

== What This Solves (Compared to Step N-1)

[cols="2,3",options="header"]
|===
| Problem from Step N-1 | How This Step Solves It

| <problem>
| <solution>
|===

== What This Does NOT Solve (Yet)

[cols="2,3",options="header"]
|===
| Remaining Problem | Addressed In

| <problem>
| xref:next-step.adoc[Step N+1]
|===

== Official Documentation

* link:https://docs.redhat.com/...[<Product Documentation>]

== Alternatives Considered

[cols="2,4",options="header"]
|===
| Approach | Notes

| <This solution>
| <Why chosen>

| <Alternative>
| <Why not chosen>
|===

'''

== Reset

<Brief explanation of what the reset does and why the order matters.>

[.console-input]
[source,bash,subs="+macros,+attributes"]
----
<undo commands in reverse order, all with --ignore-not-found and --context {context}>
----
```

---

## RBAC Verification Snippet

Use in the Verify block of any step that grants permissions:

```asciidoc
.Verify: the service account has exactly the permissions it needs
[%collapsible]
====
[.console-input]
[source,bash,subs="+macros,+attributes"]
----
oc auth can-i <verb> <resource> -n {namespace} \
  --as=system:serviceaccount:{namespace}:<sa-name> --context {context}
oc auth can-i <verb> <resource> -n default \
  --as=system:serviceaccount:{namespace}:<sa-name> --context {context}
----

[.console-output]
[source,bash]
----
yes
no
----
====
```

The second command proves the permission does not leak outside the namespace.

---

## AGENTS.md Template

```markdown
# Workshop Conventions

## Repository Purpose

<One-paragraph description of the workshop.>

## Topology

- <Single cluster (OpenShift Local / CRC) | Multi-cluster (hub + managed clusters)>
- Context names: <crc | hub, cluster-a, cluster-b> (defined in `_attributes.adoc`)

## Structure

- `documentation/` contains all AsciiDoc courseware content (Antora component)
- `documentation/modules/ROOT/pages/` contains the course pages in `.adoc` format
- YAML manifests live in the root step directories
- <list each step directory, the resources it contains, and its purpose>
- Steps are progressive: each builds on the previous one

## AsciiDoc Formatting

- Every numbered step (`===`) must have a *What* and *Why* pair in bold
- Every numbered step must have a collapsible verification block (`.Verify:` + `[%collapsible]`)
- Use `[.console-input]` before source blocks for commands
- Use `[.console-output]` before source blocks showing expected output
- Reference YAML manifests by file path in `oc apply -f` commands
- Do not use em dashes or en dashes. Use regular hyphens (`-`) instead
- Use `'''` for horizontal rules between steps
- Cross-reference other pages with `xref:page.adoc[Label]`
- External links use `link:URL[Label]`
- Use `NOTE:`, `TIP:`, `IMPORTANT:`, `WARNING:` admonitions
- All doc links must point to `docs.redhat.com` or `docs.openshift.com`
- Use attributes from `_attributes.adoc` for version numbers and context names

## CLI Conventions

- Every `oc` command must include an explicit `--context` flag
- Never use `oc login` inside step pages (only in `00-setup.adoc` and `myenv.sh`)
- YAML files with `${VARIABLE}` placeholders use `envsubst`
- All workshop variables are exported once in `00-setup.adoc`

## RBAC

- Default to namespaced Role + RoleBinding; justify any cluster-scoped binding in a comment
- Prove every permission with `oc auth can-i ... --as=system:serviceaccount:<ns>:<sa>`

## Content Rules

- Never include customer names, user names, or email addresses
- All content must be in English
- Prefer `registry.access.redhat.com` or `registry.redhat.io` images
- Use Red Hat / OpenShift-native components when they cover the use case
- Mention Red Hat products because they fit the solution, not to promote them

## YAML Conventions

- Every YAML file starts with a comment block: filename and purpose
- Use `app.kubernetes.io/part-of: <app-name>` label consistently
- Include resource requests and limits on Deployments
- Include readiness and liveness probes where applicable
- Comment any non-default value chosen for the workshop and why

## Build

- `npm run build && npm run check` must pass before every push
- Keep this file in sync with the repository when step contents change
```

---

## CLAUDE.md Template

Minimal:

```markdown
@AGENTS.md
```

With the companion subagents installed, append:

```markdown

# Orchestration (Claude Code)

The main session orchestrates; the `workshop-*` subagents do the work. All of them follow
`AGENTS.md`.

1. Context (plan mode): `workshop-docs-researcher`, `workshop-architect`. Notes go in `t/`.
2. Build: `workshop-manifest-writer`, then `workshop-module-writer`.
3. Execute: `workshop-executor` runs every step with timing.
4. Validate: `workshop-reset-validator` runs Reset and a clean re-run.
5. Review and publish: `workshop-reviewer`, `workshop-sweeper`, `workshop-style-editor`,
   `workshop-publisher`.

Rules:
- Send every failure reported by the executor or reset validator to
  `workshop-troubleshooter`. Do not diagnose it yourself, and do not let executors retry
  with changes.
- Do not accept "not supported" unless it comes from `workshop-troubleshooter` with
  `oc auth can-i` evidence and a docs reference.
- If a fix changes RBAC, endpoints or topology, send it to `workshop-architect` first, and
  update `AGENTS.md` in the same change.
- Mark a task done only when a report contains evidence for it.
```

---

## .gitignore Template

```
.DS_Store
t/
myenv.sh

# Terraform (if setup/ exists)
setup/.terraform/
setup/.terraform.lock.hcl
setup/terraform.tfstate
setup/terraform.tfstate.backup
setup/terraform.tfvars
setup/*.tfplan

# Antora / Node.js (package-lock.json is committed on purpose)
node_modules/
.cache/
gh-pages/
yarn-error.log
```

---

## README.adoc Template

```asciidoc
= <Workshop Title>

<One-paragraph summary of the workshop.>

== View the Course

The full course is published at: https://<github-user>.github.io/<repo-name>

== Local Development

To preview the course site locally:

[source,bash]
----
npm ci
npm run dev      # serves http://localhost:3000
npm run watch    # in a second terminal: rebuilds on changes
----

== Build the Site

[source,bash]
----
npm run build
npm run check
----

The generated site is output to `gh-pages/`. `npm run check` verifies that every
verification block renders as collapsible and that no template placeholders are left.

== Repository Structure

[cols="2,4",options="header"]
|===
| Directory | Purpose

| `documentation/`
| Antora courseware source (AsciiDoc pages, navigation, attributes)

| `00-<step>/`
| YAML manifests for Step 0 - <description>

| `01-<step>/`
| YAML manifests for Step 1 - <description>

| `scripts/`
| Build checks

| `setup/`
| Terraform + post-install script (internal, for provisioning clusters)
|===
```
