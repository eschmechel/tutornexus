---
title: ADR-019 - Documentation, CI Gates, and Governance
description: Docusaurus docs, pnpm, conventional commits, 1/2 approvals.
sidebar_position: 20
---

# ADR-019: Documentation, CI Gates, and Governance

- Status: Accepted
- Date: 2026-02-04

## Context

This project must avoid "black box" architecture. Documentation is a first-class deliverable.

We want:

- clear decision records (ADRs)
- auto-generated API/tool docs
- consistent commit history and changelog
- CI gates that enforce the above

## Decision

### Documentation system

**Architecture decisions:**
- ADRs in `docs/docs/adrs/*`
- Use existing ADR files as template for new ADRs
- Link new ADRs in ADR index

**API documentation:**
- OpenAPI spec generated from source using `@hono/zod-openapi`
- Zod schemas are source of truth
- Generated at build time

**TypeScript reference:**
- Typedoc generates API reference
- Published with docs site

**MCP tool documentation:**
- Generated from tool schema files (TypeScript)
- Included in docs site
- Versioned with releases

**User-facing docs:**
- Hosted on Cloudflare Pages
- Built with Docusaurus
- Source in `docs/` directory

### Commit conventions

**Format:** Conventional Commits

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation changes |
| `style` | Code style (formatting, no logic) |
| `refactor` | Code restructuring (no features or fixes) |
| `perf` | Performance improvements |
| `test` | Adding or modifying tests |
| `chore` | Build, CI, tooling |
| `revert` | Reverting a commit |
| `breaking` | Breaking change (use in footer: `BREAKING CHANGE: ...`) |

**Scopes:**

| Scope | Description |
|-------|-------------|
| `api` | Workers API changes |
| `mcp` | MCP server changes |
| `cli` | CLI tool changes |
| `web` | Frontend webapp changes |
| `adapter` | Adapter changes |
| `docs` | Documentation changes |
| `infra` | Infrastructure, CI, deployment |
| `db` | Database schema or migrations |

**Examples:**

```
feat(api): add tn_transfer_resolve tool
fix(mcp): handle missing course references
docs(adr): update ADR-012 with error conventions
refactor(cli): simplify REPL input handling
chore(infra): add pnpm workspace configuration
BREAKING CHANGE: rename tn_user_byok_list to tn_user_credentials
```

### Changelog generation

**Tool:** `git-cliff`

**Configuration:** `cliff.toml` in repo root

**Output:** `CHANGELOG.md`

**Categories aligned with commit types:**

| Commit Type | Changelog Section |
|------------|------------------|
| `feat` | Features |
| `fix` | Bug Fixes |
| `perf` | Performance |
| `docs` | Documentation |
| `refactor` | Other Changes |
| `style` | Other Changes |
| `test` | Other Changes |
| `chore` | Other Changes |

**Breaking changes** appear at the top of each version section.

### CI gates

**Required checks:**

| Check | Tool | Fails CI If... |
|-------|------|----------------|
| Linting | ESLint + markdownlint | Any lint errors |
| Type checking | TypeScript compiler | Type errors |
| Tests | Vitest + Go tests | Any test failures |
| OpenAPI generation | Custom script | Schema doesn't match |
| Docs generation | Typedoc + custom | Docs fail to generate |
| Commit messages | commitlint | Non-conventional commit |
| Broken links | Docusaurus | Broken internal links |

**Workflow:**

```yaml
on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout
      - run: pnpm install
      - run: pnpm lint
      - run: pnpm lint:markdown

  typecheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout
      - run: pnpm install
      - run: pnpm typecheck

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout
      - run: pnpm install
      - run: pnpm test

  docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout
      - run: pnpm install
      - run: pnpm docs:build  # Docusaurus

  commitlint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout
      - run: npx commitlint --from=main --to=HEAD
```

### Review process

**CODEOWNERS:**

```
/apps/web/        @rey-hanah @LMSAIH
/apps/api/        @team/docs-reviewers
/services/mcp/    @eschmechel
/services/adapters/ @team/docs-reviewers
/tools/cli/       @eschmechel @LMSAIH
/docs/            @team/docs-reviewers
```

**Approval requirements:**

| Contributor | Approvals Required |
|-------------|-------------------|
| Core team member | 1 approval |
| Outside contributor | 2 approvals (at least 1 core) |

**Doc reviewers:**
- Rotating assignment (weekly)
- Separate from code reviewers
- Focus on clarity, completeness, consistency

**Monthly doc sprints:**
- 1 day per month dedicated to documentation improvements
- Review and update stale docs
- Add missing documentation
- Improve cross-references

### Docs hosting

**Platform:** Cloudflare Pages

**Build:** Docusaurus

**URL structure:**
- `docs.tutor-nexus.com` (production)
- `docs.staging.tutor-nexus.com` (preview deployments)

**Deployment:**
- Auto-deploy on push to main
- Preview deployments for PRs

### Package manager

**Tool:** pnpm

**Workspace structure:**

```
tutornexus/
├── pnpm-workspace.yaml
├── apps/
│   ├── web/          (React frontend)
│   └── api/          (Workers backend)
├── services/
│   ├── mcp/          (Go MCP - separate go.mod)
│   └── adapters/     (TypeScript adapter Workers)
├── tools/
│   └── cli/          (Rust CLI - separate Cargo.toml)
├── packages/         (Shared TypeScript packages)
└── docs/             (Docusaurus docs)
```

**pnpm configuration:**

```yaml
packages:
  - 'apps/*'
  - 'services/adapters'
  - 'packages/*'
```

**Notes:**
- Go MCP and Rust CLI manage their own dependencies
- pnpm only manages TypeScript workspaces

## Consequences

- More up-front setup work.
- Higher quality and easier onboarding.
- Documentation stays close to code and is enforced.
- Clear contribution guidelines reduce friction.

## Alternatives considered

- Manual docs without CI gates: quickly drifts.
- npm instead of pnpm: less mature workspace support.
- Starlight instead of Docusaurus: Docusaurus provides more customization.

## Implementation notes

- Set up commitlint hook on commit.
- Configure git-cliff to generate meaningful changelogs.
- Budget time for monthly doc sprints.
- Configure Docusaurus with strict link checking (`onBrokenLinks: 'throw'`).
