---
name: antora-workshop
description: >-
  Creates a GitHub repo for Red Hat Scholars courseware workshops (AsciiDoc + Antora 3)
  with progressive hands-on steps, collapsible verification blocks, reset sections and a
  published site, for single-cluster (CRC, SNO) or multi-cluster setups. Use when asked
  for an Antora workshop, courseware site or Red Hat Scholars tutorial, or to "create a
  hands-on lab".
---

# OpenShift Workshop (Red Hat Scholars Courseware)

Creates a GitHub repository structured as a Red Hat Scholars courseware site built with
AsciiDoc and Antora. The workshop has progressive hands-on steps where each step builds on
the previous one, collapsible verification blocks, and a reset/undo section at the bottom
of every step page.

All content must be written in English. Use only Red Hat / OpenShift-native components
when they cover the use case. Never include customer names, user names, or email addresses.

Every boilerplate file you need is in [reference.md](reference.md). Do not depend on an
external reference repository.

---

## Workflow

Run the work in four phases. Do not skip a phase, and do not mark a phase done without
evidence (command output, a report, or a passing check).

1. **Context gathering** (no cluster changes). Collect requirements in a gitignored `t/`
   folder: topic, target audience, topology (see below), product versions, which
   features each step demonstrates, and links to the official docs for each feature.
   Verify every product fact (API versions, field names, operator namespaces, defaults)
   against `docs.redhat.com` before it reaches a manifest.
2. **Build and execute**. Write manifests and pages, then run the full workshop end to
   end against a live cluster exactly as a participant would, recording wall-clock time
   for every sub-step. Fix what fails, then re-run the affected steps.
3. **Reset validation**. Run every `== Reset` section, confirm the cluster is clean (no
   leftover namespaces, CRs, RBAC, subscriptions or finalizers), then re-run the whole
   workshop from that clean state. Anything that only worked the first time is a bug.
4. **Render and publish**. Build the site, run `scripts/check-site.sh` (see
   [reference.md](reference.md)), open the rendered pages, then push and confirm the CI
   run and the published URL.

If the session supports subagents (Claude Code), the companion agents in this repository
under `agents/antora-workshop/` split these phases across specialized workers. See
**Claude Code subagents** below.

---

## Topology

Decide the topology in phase 1 and keep it consistent everywhere (pages, `myenv.sh`,
`_attributes.adoc`, `AGENTS.md`). The templates use attributes so pages do not hard-code
context names.

| Topology | Typical environment | Context names | `00-setup.adoc` options |
|---|---|---|---|
| Single cluster | OpenShift Local (CRC), SNO, one lab cluster | `crc` (or one name of your choice) | Option A: local CRC from scratch. Option B: an existing cluster |
| Multi-cluster | Hub + managed clusters (ACM, Submariner, etc.) | `hub`, `cluster-a`, `cluster-b` | Option A: pre-provisioned clusters from scratch. Option B: quick login |

Remove anything that does not apply. A single-cluster workshop must not mention hub,
managed clusters, or cluster mapping tables.

### OpenShift Local (CRC) notes

When the workshop targets CRC, document these in `00-setup.adoc`:

- Resources: `crc config set memory 16384` and `crc config set cpus 6` as a starting point
  when the workshop uses monitoring or operators. Adjust upward for heavier products.
- Monitoring is off by default: `crc config set enable-cluster-monitoring true` before
  `crc start` if any step uses Prometheus, alerts, or metrics-based triggers. Enable user
  workload monitoring in-cluster if steps scrape user workloads.
- Credentials: `crc console --credentials` prints the `kubeadmin` login command.
- Scrape intervals on CRC are long (cAdvisor metrics every ~60 seconds). Size PromQL
  `rate()` windows to at least twice the scrape interval (e.g. `[2m]`), or queries return
  empty results silently.

---

## Repository Structure

```
<workshop-slug>/
├── README.adoc                          # Repo overview, local dev, structure table
├── .gitignore
├── AGENTS.md                            # AI conventions (Cursor, Codex, Copilot, Claude Code)
├── CLAUDE.md                            # Claude Code entry point (imports AGENTS.md)
├── Dockerfile                           # Antora build + UBI httpd container
├── package.json                         # Pinned npm dependencies (Antora 3)
├── package-lock.json                    # Committed: CI installs exactly these versions
├── site.yml                             # Antora playbook (production)
├── dev-site.yml                         # Antora playbook (local dev)
├── site.sh                              # Shell shortcut for a clean production build
├── scripts/
│   └── check-site.sh                    # Post-build checks (collapsibles, placeholders, em dashes)
├── supplemental-ui/                     # Custom UI overrides
│   ├── .nojekyll
│   ├── ui.yml
│   └── partials/footer-nav.hbs
├── .github/workflows/docs.yml           # CI: build, check, deploy to GitHub Pages
├── documentation/                       # Antora component source
│   ├── antora.yml
│   └── modules/ROOT/
│       ├── nav.adoc                     # Left-nav tree
│       ├── images/                      # Screenshots and diagrams
│       └── pages/
│           ├── _attributes.adoc         # Shared AsciiDoc attributes
│           ├── index.adoc               # Landing page with tile grid
│           ├── 00-setup.adoc            # Cluster/env setup (always page 00)
│           ├── 01-<step-name>.adoc      # First hands-on step
│           ├── 02-<step-name>.adoc      # Builds on step 01
│           └── ...                      # Additional steps
├── 00-<step-zero-dir>/                  # YAML manifests for step 0 (baseline)
│   └── *.yaml
├── 01-<step-name>/                      # YAML manifests for step 1
│   └── *.yaml
├── kustomize/                           # Optional: Kustomize base + overlays
├── setup/                               # Optional: Terraform + post-install (internal)
└── myenv.sh                             # Personal env file (gitignored)
```

YAML manifests live in root step directories (e.g. `01-acm/`) and are referenced
directly from AsciiDoc pages via `oc apply -f 01-acm/<file>.yaml`. No `manifests/`
subfolders. Steps are progressive: each builds on the previous one.

The `setup/` directory is internal-only (for Red Hatters provisioning infrastructure)
and is not part of the workshop itself.

---

## Documentation Framework: Antora

The courseware site uses **Antora 3** (`@antora/cli` + `@antora/site-generator`) with the
Red Hat Scholars UI bundle (`rhd-tutorial-ui` v0.1.10).

Do not use Antora 2.x. Antora 2.x ships `asciidoctor.js` 1.5.9, which does not support
`[%collapsible]` (added in Asciidoctor 2.0.6). The pages look correct in the source, but
every verification block renders as a plain, always-open "Example N." block.

Create every boilerplate file from [reference.md](reference.md): `package.json`,
`site.yml`, `dev-site.yml`, `antora.yml`, `site.sh`, `Dockerfile`, `supplemental-ui/`,
`scripts/check-site.sh`, and `.github/workflows/docs.yml`.

- Install: `npm install` once to create `package-lock.json`, then commit the lockfile.
- Local dev: `npm run dev` serves `gh-pages/` at http://localhost:3000. Run `npm run watch`
  in a second terminal to rebuild on changes.
- Build: `npm run build` (output in `gh-pages/`), then `npm run check`.

No AsciiDoc extensions are required. If a workshop genuinely needs tabbed content, use the
official `@asciidoctor/tabs` extension (see the optional section in
[reference.md](reference.md)). Do not copy legacy `lib/tab-block.js` or
`lib/remote-include-processor.js`; they target the Asciidoctor 1.5 API.

---

## Resolving Placeholders

Templates use `<...>` placeholders. Resolve every one of them before the first commit:

- `<github-user>` and `<repo-name>`: take them from `git remote get-url origin`. If the
  repository has no remote yet, ask the user. Never guess.
- `<workshop-slug>`: the repository name in lowercase kebab-case.
- `<Workshop Title>`: from the user's request.

Before finishing, `scripts/check-site.sh` must report no unresolved placeholders. A
published site with `<github-user>` in the footer or README is a defect.

The only placeholders allowed in the final repository are `${VARIABLE}` tokens in YAML
files that are filled with `envsubst` and exported in `00-setup.adoc`.

---

## AsciiDoc Page Structure

### _attributes.adoc

Shared attributes for version numbers and context names. Every step page must
include it on line 2: `include::_attributes.adoc[]`

### nav.adoc

Left-nav tree using `xref:` with `#anchor` targets for sub-sections.

### index.adoc

Landing page with a tile grid (`[.tiles.browse]`) and an environment table. Do not set
`:page-layout: home`: `rhd-tutorial-ui` has no `home` layout and Antora logs a warning and
falls back to the default. See [reference.md](reference.md) for all page templates.

---

## AsciiDoc Formatting Rules

### What/Why pairs

Every numbered sub-step must start with bold What and Why:

```asciidoc
=== 1. Sub-step title

*What:* One sentence describing the concrete action.

*Why:* One sentence explaining why this step matters.
```

Use `==` for page sections (`== Steps to Apply`, `== Reset`) and `===` for numbered
sub-steps on every page, including `00-setup.adoc`. Do not mix levels between pages.

### Timing annotations

When a sub-step takes more than 10 seconds to complete (operator installs, pod readiness
waits, API warmup, large downloads), add a timing annotation line immediately above the
What/Why pair using the `icon:clock[]` macro. Round to the nearest meaningful unit.
Skip the annotation entirely for steps that complete in under 10 seconds.

```asciidoc
=== 5. Create the operator instance

icon:clock[] ~1 minute (CR accepted in ~10s, pods ready in ~45s)

*What:* Deploy the custom resource in the target namespace.

*Why:* This is the management plane for the product.
```

Timings must be measured by running the full workshop end-to-end and recording
wall-clock duration for each sub-step. Include a parenthetical breakdown when the wait
has distinct phases (e.g., CR creation vs pod readiness vs API warmup). Typical timings
to annotate:

- Operator installs (subscription + CSV readiness): ~30 seconds
- Custom resource deployments (pods scheduling + running): ~1-2 minutes
- API warmup after deployment (database migrations, initial loading): ~2-3 minutes
- Database hydration (vulnerability DBs, index builds, profile parsing): 15-30 minutes (background)
- Large file downloads (offline bundles, mirror content): ~5 minutes

Add an `IMPORTANT:` admonition for background processes that take 15+ minutes (like
database hydration or large index builds) so participants know to start setup early.

### Demo-friendly timing

Default controller timings are tuned for production, not for a 10-minute lab. When a step
waits on a controller (autoscaler cooldowns, HPA scale-down stabilization, sync intervals,
reconcile periods), shorten the relevant setting in the workshop manifest, add a YAML
comment explaining why, and add a `NOTE:` telling participants the production default.

### Console input/output blocks

Commands the user should run:

```asciidoc
[.console-input]
[source,bash,subs="+macros,+attributes"]
----
oc apply -f 01-step/resource.yaml --context {context}
----
```

Expected output:

```asciidoc
[.console-output]
[source,bash]
----
NAME       READY   STATUS    RESTARTS   AGE
my-pod     1/1     Running   0          30s
----
```

### Collapsible verification blocks

Every numbered sub-step must have a verification block, including setup steps such as
cloning the repository or exporting variables (verify with `git remote -v`, `env | grep`,
etc.). When a step is split into sub-parts (4a, 4b), each sub-part needs its own block.

```asciidoc
.Verify: Description of what to check
[%collapsible]
====
[.console-input]
[source,bash,subs="+macros,+attributes"]
----
oc get pods -n demo-app --context {context}
----

[.console-output]
[source,bash]
----
NAME       READY   STATUS    RESTARTS   AGE
my-pod     1/1     Running   0          30s
----
====
```

The source being correct is not enough: confirm the rendered HTML contains a `<details>`
element for every `[%collapsible]` block. `scripts/check-site.sh` does this.

### Horizontal rules between steps

Use `'''` (three single quotes) between sub-steps for visual separation.

### Admonitions

```asciidoc
NOTE: Informational note.
TIP: Helpful suggestion.
IMPORTANT: Must-read information.
WARNING: Potential pitfall or danger.
```

### Cross-references and links

```asciidoc
xref:page.adoc[Label]                              # internal page
xref:page.adoc#anchor[Label]                        # internal anchor
link:https://docs.redhat.com/...[Label]             # external link
```

### Other AsciiDoc patterns

- **Tables**: `[cols="2,3",options="header"]` with `|===` delimiters
- **Images**: Place in `documentation/modules/ROOT/images/`, reference as `image::filename.png[Alt text]`
- **Collapsible blocks**: `.Title` + `[%collapsible]` + `====` delimiters (used for alternative approaches too)

---

## Screenshots from the UI

Screenshots orient participants in web consoles where navigation paths and visual
layout are hard to convey with text alone. They must always be captured by the AI
using its browser tools against the live environment - never from user-provided files,
stock images, or fabricated mockups.

### When to add screenshots

Add a screenshot only when it helps a participant find something in the UI that
words alone make ambiguous. Good candidates:

- **First time a UI section is introduced** in the workshop (e.g. the first visit
  to a product dashboard, a vulnerability results page, a network graph). One
  screenshot per major UI area is enough; do not screenshot the same page again in
  later steps unless it looks materially different.
- **Complex navigation paths** where the sidebar label, page heading, and tab names
  differ from each other (e.g. sidebar says "Results", page heading says "User
  workload vulnerabilities", sub-tabs say "User Workloads / Platform / Nodes").
- **Non-obvious UI interactions** like kebab/overflow menus, hidden filters, or
  multi-step modal dialogs where the participant needs to know what to look for.
- **Before-and-after comparisons** where a step produces a visible change (e.g.
  violations appearing after deploying workloads, risk scores dropping after
  remediation).

Do NOT add screenshots for:

- CLI-only steps with no UI component.
- Pages that are self-explanatory from the navigation path (e.g. "Platform
  Configuration > Policy Management" when the page is just a list).
- Repeated visits to the same UI page unless the data shown has changed in a way
  that matters to the narrative.
- Login screens, confirmation dialogs, or generic "success" banners.

If the session has no browser tools, skip screenshots and say so in the final report.
Never substitute images from other sources.

### Capture workflow

1. **Navigate** to the target page using your browser tools with the product's
   route URL. Wait 2-3 seconds for the page to fully render before proceeding.

2. **Set up the view** before capturing. Apply any filters, expand the right
   sidebar section, or select the tab that the docs tell participants to use.
   The screenshot should show exactly what a participant would see after
   following the written instructions.

3. **Take the screenshot** using your screenshot tool. The image will be saved
   to a temporary location.

4. **Copy to the images directory**:
   ```bash
   cp <screenshot-path> \
      documentation/modules/ROOT/images/<NN>-<descriptive-name>.png
   ```
   Use the step number prefix (`04-`, `05-`, etc.) so images sort alongside
   their page files. Use lowercase kebab-case for the descriptive part.

5. **Reference in AsciiDoc** with a caption line above the `image::` macro:
   ```asciidoc
   .Dashboard - risk overview after deploying vulnerable workloads
   image::04-dashboard-risk-overview.png[ACS dashboard showing risk indicators for the acs-workshop namespace]
   ```
   The `.Title` line becomes a figure caption. The `[Alt text]` in brackets is
   for accessibility and should describe what the image shows, not repeat the
   caption.

#### Cursor-specific example

When running this skill in Cursor, the capture workflow uses these specific tools:

1. Navigate with `browser_navigate` using the product's route URL.
2. Wait for the page to render using `AwaitShell` with `block_until_ms: 3000`.
3. Apply filters or select tabs using `browser_click`, `browser_fill`, etc.
4. Capture with `browser_take_screenshot` (saves to a temporary directory,
   e.g. `/var/folders/.../cursor/screenshots/`).
5. Copy the resulting file to `documentation/modules/ROOT/images/`.

#### Claude Code-specific example

In Claude Code, a Playwright MCP server provides the browser tools. It needs Node.js 18
or later in the shell that launched Claude Code (open a new terminal after switching
Node versions with `nvm`, or the MCP server fails to connect).

### Naming convention

```
<step-number>-<ui-area-or-feature>.png
```

Examples:
- `04-dashboard-risk-overview.png`
- `05-workload-cves.png`
- `06-network-graph.png`
- `07-violations.png`

Keep names short. One or two screenshots per step is typical; rarely more than
three.

### UI label verification

After all screenshots are placed, do a verification pass: for every navigation
instruction in the docs (bold text like `*Vulnerability Management > Results >
User Workloads*`), open that path in the browser and confirm the sidebar link
name, page heading, tab labels, filter options, and button names match exactly.
Product UIs rename elements between versions. Common mismatches to watch for:

- Sidebar link name differs from the page heading (e.g. sidebar: "Results",
  heading: "User workload vulnerabilities").
- Tab names that changed between product versions (e.g. "Authentication Tokens"
  renamed to "Authentication").
- Filter attributes that live under a non-obvious entity selector (e.g.
  "Lifecycle stage" is an attribute of the "Policy" entity, not a top-level
  filter).

Fix any mismatches in the adoc files immediately. Do not leave stale UI
references for participants to stumble over during a live session.

---

## CLI Conventions

- Every `oc` command must include an explicit `--context` flag. Use the attribute
  (`--context {context}`, `--context {hub-context}`) in pages so context names live in
  `_attributes.adoc` only. Never use `oc login` inside step pages.
- Context setup is done once in `00-setup.adoc` (and in `myenv.sh`).
- YAML files with `${VARIABLE}` placeholders must be applied via:
  ```bash
  envsubst < file.yaml | oc apply --context <ctx> -f -
  ```
  Document the `envsubst` requirement above the apply command so participants
  understand why a plain `oc apply -f` would fail (the `${}` tokens would be
  applied as literal strings).
- CLI tools that connect to services with self-signed TLS certificates (e.g.
  product CLIs, `curl -sk`) must include appropriate TLS skip flags
  (`--insecure-skip-tls-verify` for most Red Hat CLIs, `-sk` for `curl`). Add a `NOTE:`
  explaining that production environments should trust the CA instead.
- API commands that require a specific query parameter (e.g. `cluster_id`) must
  document how to retrieve that parameter first (e.g. querying `/v1/clusters`).
  When an API endpoint exists at different versions (`/v1/` vs `/v2/`), document
  which version to use and note discrepancies.
- All workshop variables are exported once in `00-setup.adoc`.
- Include a variables table in `00-setup.adoc`:
  ```asciidoc
  [cols="2,2,4",options="header"]
  |===
  | Variable | Used in | Description
  | `GIT_REPO_URL` | `01-step/applicationset.yaml` | Git clone URL
  |===
  ```

---

## RBAC and Least Privilege

Workshops teach patterns that participants copy into production. Model least privilege:

- Default to a namespaced `Role` + `RoleBinding`. Use a `ClusterRole` or
  `ClusterRoleBinding` only when the resource is cluster-scoped or the product
  documentation requires it, and say why in a YAML comment.
- List exact verbs, resources and subresources (e.g. `create` on `serviceaccounts/token`
  for bound service account tokens). Do not grant `*`.
- Prefer tenant-scoped endpoints when a product offers both (e.g. the thanos-querier
  tenancy port `9092` with a namespace parameter instead of the cluster-wide `9091`).
- Every RBAC step's verification block proves the permission with
  `oc auth can-i <verb> <resource>[/<subresource>] -n <ns> --as=system:serviceaccount:<ns>:<sa> --context <ctx>`.
- Use bound, short-lived service account tokens instead of long-lived token secrets
  when the product supports them.

---

## Troubleshooting Rules

When a step fails during execution:

- Capture the literal error and the cluster state (`oc get`, `oc describe`, logs, events)
  before changing anything.
- Form at least two hypotheses and test each with evidence.
- Never conclude that a feature is unsupported or a product limitation until every
  permission involved has been verified with `oc auth can-i` and the exact feature has
  been checked in the official documentation for the installed version. Missing RBAC,
  wrong ports, wrong namespaces and environment timing (scrape intervals, stabilization
  windows) are far more common than product bugs.
- Distinguish waiting from failing: an operator install or a scale event that is still in
  progress is not an error until a reasonable timeout passes.
- Record the root cause as an inline `NOTE:` when participants could hit it too.

---

## YAML Conventions

- Every YAML file starts with a comment block: `# filename.yaml` + `# Purpose: ...`
- Use `app.kubernetes.io/part-of: <app-name>` label consistently.
- Include resource requests/limits and readiness/liveness probes on Deployments.
- YAML files live in step directories and are referenced from AsciiDoc pages.
- Comment any non-default value chosen for the workshop (shortened timers, rate windows,
  tenancy ports) with the reason.
- Validate every file with `oc apply --dry-run=server -f <file> --context <ctx>` (pipe
  through `envsubst` first when the file has `${VARIABLE}` tokens).

---

## Step Page Structure

Every step page (except setup) follows this order:

1. **Title**: `= Step N - Title: Descriptive Subtitle`
2. **Include**: `include::_attributes.adoc[]`
3. **Intro paragraph**: What this step does and what problem from the previous step it solves
4. **Prerequisites**: Bullet list linking to previous step
5. **How It Works** (optional): Brief architectural explanation
6. **Steps to Apply**: Numbered sub-steps with What/Why, console blocks, and Verify blocks
7. **What This Solves**: Table comparing to previous step
8. **What This Does NOT Solve (Yet)**: Table with xref to next step
9. **Official Documentation**: Links to `docs.redhat.com`
10. **Alternatives Considered**: Neutral comparison table
11. **Reset**: Undo commands for this step

See [reference.md](reference.md) for the complete step page template.

---

## Reset / Undo Sections

Every step page MUST end with a `== Reset` section containing the exact commands to
undo everything from that step and return to the state before it. Key rules:

1. **Reverse order**: Undo resources in reverse order of creation.
2. **Use `--ignore-not-found`**: So the reset is idempotent.
3. **Wait for finalizers**: Use `--wait` or `oc wait --for=delete` when resources have
   finalizers (e.g. ApplicationSets cascade-delete Applications).
4. **Remove labels and taints**: Clean up any labels or taints added to clusters.
5. **Preserve cloud credentials**: Don't delete cloud credential secrets that are
   expensive to recreate.
6. **Explain the order**: Add a brief sentence explaining why the order matters.
7. **Validated**: Every Reset section has been run in phase 3 and followed by a clean
   re-run of the step.

---

## 00-setup.adoc Page

The setup page is special. It provides two paths that depend on the topology (see
**Topology**):

- **Multi-cluster**: Option A - pre-provisioned clusters (Demo Platform), full setup from
  scratch including gathering credentials, importing clusters, installing operators.
  Option B - quick login to clusters already configured by someone else.
- **Single cluster**: Option A - local OpenShift Local (CRC) from scratch, including
  resource and monitoring settings. Option B - an existing cluster with the operators
  already installed.

Must include:
1. Prerequisites (tools, versions, permissions)
2. Cluster mapping table (multi-cluster only)
3. Login and context rename instructions
4. Operator installation and verification
5. Workshop variable exports with a variable table
6. Clone repository step

Every numbered sub-step on this page also has What/Why and a collapsible Verify block.

---

## Content Rules

- Never include customer names, user names, or email addresses.
- All content must be in English.
- Prefer `registry.access.redhat.com` or `registry.redhat.io` images over Docker Hub.
- Use Red Hat / OpenShift-native components when they cover the use case.
- Mention Red Hat products because they fit the solution, not to promote them.
- Do not use em dashes (the long dash, Unicode U+2014) or en dashes (U+2013). Use a
  regular hyphen (`-`) instead. `scripts/check-site.sh` fails on them.
- All doc links must point to `docs.redhat.com` or `docs.openshift.com` - no placeholders.
  Upstream project docs may inform research but are not linked from the pages.

---

## Platform-Specific Notes

When a workshop runs on managed OpenShift (ROSA HCP, ARO, etc.), document any
differences from self-managed OCP that affect the workshop steps. Use `NOTE:`
admonitions inline rather than separate pages. Common differences:

- **ROSA HCP / ARO**: No control plane access. Operators and features that inspect
  or configure control-plane components (e.g. etcd, API server audit config,
  platform-level compliance profiles) may be unavailable or behave differently.
  Document which profiles, APIs, or features are node-only on managed platforms.
- **Managed clusters**: May use `cluster-admin` instead of `kubeadmin` for
  authentication. The `myenv.sh` login pattern works the same way.
- **OpenShift Local (CRC)**: see **Topology > OpenShift Local (CRC) notes**.
- **Operator versions**: Operator behavior and API endpoints can change between
  versions. When a workshop documents API calls, note the tested version in
  `_attributes.adoc` and call out any version-specific behavior (e.g. an endpoint
  that requires a query parameter in newer versions, or a v1/v2 API discrepancy).

---

## Operational Notes and Caveats

When executing the workshop reveals behaviors that are not obvious from the
documentation alone, add inline `NOTE:`, `IMPORTANT:`, or `TIP:` admonitions.
These should cover:

- **Async processes**: If an operator or service needs background time to initialize
  (e.g. a database hydrating indexes, an operator parsing profile bundles), add an
  `IMPORTANT:` admonition with a concrete log-check command so participants can
  verify readiness before proceeding.
- **API quirks**: If an API requires a precondition that is not obvious (e.g. creating
  a dependent resource before the main one, or needing a specific integration
  configured first), document the workaround inline with a `NOTE:`.
- **Behavioral differences**: If a feature behaves differently than participants might
  expect from its name or documentation (e.g. an enforcement action that works on
  Deployments but not bare Pods), explain the distinction clearly.
- **Approval workflows**: If an action creates a request that requires a different
  user to approve it, document this so participants do not get stuck waiting.
- **Certificate/TLS issues**: Self-signed certificates are common in workshop
  environments. Document TLS skip flags (e.g. `--insecure-skip-tls-verify` for CLIs,
  `-sk` for `curl`) with a note that production should trust the CA instead.
- **Image rescans**: If images are deployed before a scanner database finishes loading,
  they may show zero results. Document how to trigger a rescan or how long to wait.
- **Metrics latency**: Metrics-driven steps (autoscaling, alerts, dashboards) depend on
  scrape intervals. Tell participants how long to wait before the first data point and
  give a query they can run to confirm data exists.

---

## AGENTS.md and CLAUDE.md

Create two files in the workshop root so that AI tools follow the project conventions:

- **AGENTS.md**: Contains the full workshop conventions (repository purpose, topology,
  structure, AsciiDoc formatting, CLI conventions, RBAC rules, content rules, and YAML
  conventions). This file is read automatically by Cursor, Codex, Copilot, and most other
  AI coding tools. Keep it in sync with the repository: when a step's resources change
  (e.g. a ClusterRoleBinding replaced by a namespaced RoleBinding), update `AGENTS.md` in
  the same commit.
- **CLAUDE.md**: Starts with `@AGENTS.md` so Claude Code imports the shared conventions.
  When the companion subagents are installed, append the orchestration section from
  [reference.md](reference.md). Claude Code-specific instructions go here, not in
  `AGENTS.md`.

See [reference.md](reference.md) for both templates.

---

## .gitignore

Must cover: `.DS_Store`, `myenv.sh`, `t/`, Terraform state files (if `setup/` exists),
`node_modules/`, `.cache/`, `gh-pages/`.

Do NOT ignore `package-lock.json`. CI runs `npm ci`, which requires the lockfile, and the
lockfile is what guarantees CI builds with the same Antora version you tested locally.

Also gitignore any environment-specific artifacts generated during the workshop that
contain secrets or are environment-bound:

- **Generated secret bundles** (e.g. init bundles, TLS certificates) - contain
  credentials tied to a specific deployment. Stale bundles from a previous run cause
  authentication or certificate errors on a new deployment.
- **Offline data bundles** (e.g. downloaded DB updates, mirror archives) - large binary
  files that are environment-specific.
- **CLI binaries** (e.g. downloaded product CLIs) - platform-specific, should not be
  committed.

See [reference.md](reference.md) for the full template.

---

## myenv.sh

`myenv.sh` is a personal, gitignored shell script that each workshop participant creates
to store their environment-specific credentials and cluster endpoints. Running
`source myenv.sh` authenticates to every cluster and sets up the named `oc` contexts
used throughout the workshop. It is the single place where sensitive values live - no
credentials should appear in any other file.

### Structure (multi-cluster)

```bash
# Console URLs (for quick reference - not used by scripts)
# Hub console:       https://console-openshift-console.apps.<hub-domain>
# Cluster A console: https://console-openshift-console.apps.<cluster-a-domain>
# Cluster B console: https://console-openshift-console.apps.<cluster-b-domain>

# -- Workshop variables (used by envsubst in YAML manifests) --
export HUB_API_URL="https://api.<hub-domain>:6443"
export CLUSTER_A_API_URL="https://api.<cluster-a-domain>:6443"
export CLUSTER_B_API_URL="https://api.<cluster-b-domain>:6443"

export GIT_REPO_URL="https://github.com/<org>/<repo>.git"
export REMOTE_INGRESS_IP="<set after Submariner - see step 02>"
# Add any additional workshop variables here

# -- Context cleanup (idempotent) --
oc config delete-context hub 2>/dev/null
oc config delete-context cluster-a 2>/dev/null
oc config delete-context cluster-b 2>/dev/null

# -- Login + rename contexts --
oc login "$HUB_API_URL" --username <user> --password <password>
oc config rename-context "$(oc config current-context)" hub

oc login "$CLUSTER_A_API_URL" --username <user> --password <password>
oc config rename-context "$(oc config current-context)" cluster-a

oc login "$CLUSTER_B_API_URL" --username <user> --password <password>
oc config rename-context "$(oc config current-context)" cluster-b
```

### Structure (single cluster, OpenShift Local)

```bash
# Console: https://console-openshift-console.apps-crc.testing

# -- Workshop variables (used by envsubst in YAML manifests) --
export CLUSTER_API_URL="https://api.crc.testing:6443"
export WORKSHOP_NAMESPACE="<namespace>"
# Add any additional workshop variables here

# -- Context cleanup (idempotent) --
oc config delete-context crc 2>/dev/null

# -- Login + rename context (password from: crc console --credentials) --
oc login "$CLUSTER_API_URL" --username kubeadmin --password <password>
oc config rename-context "$(oc config current-context)" crc
```

The `<...>` values in `myenv.sh` are filled by each participant and are the only
angle-bracket placeholders allowed, because the file is never committed.

### Key rules

1. **Gitignored**: `myenv.sh` must be listed in `.gitignore`. It contains passwords.
2. **Console URLs as comments**: Put web console URLs at the top as comments for quick
   copy-paste into a browser. These are not used by any script.
3. **Exports first**: All `export` variables that YAML manifests reference via `envsubst`
   go at the top, before any `oc` commands.
4. **Context cleanup before login**: Delete existing contexts before logging in so the
   script is idempotent. Running `source myenv.sh` twice must not fail.
5. **Login + rename pattern**: Each cluster follows the same pattern:
   `oc login` then `oc config rename-context "$(oc config current-context)" <name>`.
   This gives deterministic context names regardless of the auto-generated context string.
6. **Match 00-setup.adoc**: The context names and variable names in `myenv.sh` must
   exactly match what `00-setup.adoc` and `_attributes.adoc` document. The setup page
   tells participants *what* to put in `myenv.sh`; the file itself is their personal copy.
7. **Adapt to the workshop**: Add or remove `export` lines to match the variables table in
   `00-setup.adoc`.

---

## GitHub Actions CI

The workflow installs exactly the locked dependencies with `npm ci`, builds the site with
Antora 3, runs `scripts/check-site.sh`, and only then deploys `gh-pages/` with
`JamesIves/github-pages-deploy-action@v4`. A failed check blocks the deploy, so a broken
render never reaches the published site.

Do not use `kameshsampath/antora-site-action@master`: it pulls an unpinned Antora version,
so CI can build with a different toolchain than the one you tested.

See [reference.md](reference.md) for the exact workflow YAML. After the first push,
confirm the run with `gh run watch` and check the published URL.

---

## Claude Code Subagents

This repository ships optional companion subagents in `agents/antora-workshop/`. The
install script links them into `~/.claude/agents/`. Each one has a fixed model and effort
level, so expensive reasoning is used only where a wrong conclusion would propagate:

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

When they are installed, run the main session with `claude --model opusplan` and add the
orchestration section from [reference.md](reference.md) to the workshop's `CLAUDE.md`.
When they are not installed, follow the same phases in a single session.

---

## Quality Checklist

Before finishing:

- [ ] All AsciiDoc pages are in English
- [ ] Topology decided and consistent across pages, `_attributes.adoc`, `myenv.sh`, `AGENTS.md`
- [ ] `_attributes.adoc` defines all version and context attributes used across pages
- [ ] Every step page includes `\include::_attributes.adoc[]` on line 2
- [ ] Every numbered sub-step (including `00-setup.adoc` and sub-parts like 4a/4b) has *What*/*Why* bold pairs
- [ ] Every numbered sub-step has a `.Verify:` collapsible block
- [ ] `'''` horizontal rules separate sub-steps
- [ ] Every `oc` command has an explicit `--context` flag
- [ ] No `oc login` inside step pages (only in `00-setup.adoc`)
- [ ] YAML files with `${VARIABLE}` use `envsubst` in apply commands
- [ ] Every YAML file has a comment header (filename + purpose) and passes a server dry-run
- [ ] RBAC is least privilege and every permission is proven with `oc auth can-i`
- [ ] Every step page ends with a `== Reset` section
- [ ] Reset commands use `--ignore-not-found` and reverse order, and were validated with a clean re-run
- [ ] Timing annotations come from a real end-to-end run
- [ ] `nav.adoc` lists all pages with anchor-level sub-items
- [ ] `index.adoc` has tile grid linking to all steps and no `:page-layout: home`
- [ ] `00-setup.adoc` has Options A and B for the chosen topology, variable table, and clone step
- [ ] Steps are progressive (each builds on the previous)
- [ ] "What This Solves" and "What This Does NOT Solve" tables present
- [ ] Official Documentation section links to `docs.redhat.com`
- [ ] Alternatives Considered table is neutral (no sales language)
- [ ] No em dashes, no customer names, no placeholder doc links
- [ ] No unresolved `<...>` placeholders outside `myenv.sh`
- [ ] `AGENTS.md` and `CLAUDE.md` created and in sync with the repository
- [ ] `package.json` uses Antora 3 and `package-lock.json` is committed
- [ ] `.github/workflows/docs.yml` uses `npm ci` and runs `scripts/check-site.sh` before deploy
- [ ] `npm run build && npm run check` passes locally
- [ ] Rendered pages opened in a browser: Verify blocks collapse, nav works, copy buttons work
- [ ] CI run green and published URL loads
- [ ] `site.yml` and `dev-site.yml` configured with correct URLs
- [ ] `.gitignore` covers all generated/sensitive files and does not ignore `package-lock.json`
- [ ] Screenshots captured from the live UI via the AI's browser (no fabricated images)
- [ ] Screenshots placed only where UI navigation is ambiguous or a new section is introduced
- [ ] Screenshot filenames use `<NN>-<descriptive-name>.png` convention
- [ ] Every UI navigation path in the docs verified against the actual product UI
- [ ] Sidebar labels, page headings, tab names, and button labels match the live UI exactly
