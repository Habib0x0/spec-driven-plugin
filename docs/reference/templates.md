# Templates

When you run `/spec <name>`, the plugin asks whether to start from a preset template or from scratch. Presets pre-fill `requirements.md` with user stories covering common scenarios for that feature type. The spec-planner customizes them based on your answers.

## Available presets

### REST API

The REST API preset covers a standard resource-oriented API with:

- **CRUD operations** — POST, GET, PUT, DELETE with appropriate status codes (201, 200, 204, 404)
- **Input validation** — required fields, type checking, length/range constraints, handling of unknown fields
- **Authentication and authorization** — bearer token validation (401), role-based access control (403)
- **Error responses** — consistent JSON error structure with `error.code`, `error.message`, and `error.details` across all endpoints
- **Pagination** — `page` and `per_page` query parameters, response metadata with `total`, `page`, `per_page`, `total_pages`, default page size of 20, maximum of 100

Non-functional requirements included: 200ms p95 response for collection endpoints, 100ms p95 for individual resource endpoints, HTTPS required, no internal details in error responses.

Pre-filled open questions prompt you to decide: authentication mechanism (JWT, API key, OAuth2), database and ORM, soft-delete vs hard-delete behavior.

### React Page

The React Page preset covers a data-driven page with:

- **Component rendering** — page layout, data display, list item rendering
- **Routing** — client-side navigation, browser back/forward, deep linking
- **State management** — UI updates on user actions, filter/sort state, session state restoration
- **API integration** — data fetching on mount, mutation requests, optimistic or server-driven state updates
- **Loading and error states** — loading indicators, error messages with retry buttons, empty states
- **Responsive layout** — desktop layout at 768px and above, mobile-friendly stacking below, ARIA labels

Non-functional requirements included: Largest Contentful Paint under 2.5 seconds on 4G, interaction feedback within 100ms, WCAG 2.1 AA color contrast, no XSS, API tokens not exposed in client-accessible storage.

Pre-filled open questions cover: UI framework/component library, state management approach, data fetching library.

### CLI Tool

The CLI Tool preset covers a command-line binary with:

- **Argument parsing** — positional arguments, optional flags with defaults, unrecognized flag errors with usage output
- **Subcommands** — routing to subcommand handlers, help when invoked without a subcommand, error on unrecognized subcommand
- **Output formatting** — table (default), JSON (parseable by `jq`), plain (tab-separated, no headers); error on unsupported format value
- **Error handling** — errors to stderr with non-zero exit codes, exit code 1 for user errors, exit code 2 for internal errors, no stack traces unless `--verbose`/`--debug` is set
- **Help and version text** — `--help`/`-h` globally and per-subcommand, `--version`/`-v` with tool name and version number

Non-functional requirements included: startup and output within 500ms for local operations, cross-platform support for macOS and Linux (x86_64 and arm64), all errors to stderr.

Pre-filled open questions cover: implementation language (Go, Python, Rust, TypeScript), argument parsing library, `--quiet` flag support.

## Starting from scratch

Choose "from scratch" to start with a blank requirements template. The spec-planner will ask clarifying questions and build requirements specific to your feature without any pre-filled assumptions.

## Template variables

Templates use `{{PLACEHOLDER}}` syntax for values that the spec-planner substitutes based on your feature context. You do not interact with these directly — the agent handles substitution during the spec creation conversation.

## Adding custom presets

See [Extending the plugin](../advanced/extending.md) for how to add your own preset templates.
