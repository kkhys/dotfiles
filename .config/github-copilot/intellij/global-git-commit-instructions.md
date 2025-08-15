# Git Commit Instructions

This file provides Claude Code with specific guidance for making commits in this repository.

## Commit Message Format

Use Conventional Commits format with English messages:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Character Limits

Following GitHub's recommendations:

- **Subject line**: Maximum 72 characters (recommended 50)
- **Body lines**: Maximum 72 characters per line
- **Total message**: No hard limit, but keep concise

#### Subject Line Guidelines
- Start with lowercase after the scope
- No period at the end
- Use imperative mood ("add" not "added" or "adds")
- Be descriptive but concise

### Types
- `feat`: New features
- `fix`: Bug fixes
- `docs`: Documentation updates
- `style`: Code formatting (no functional changes)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding or modifying tests
- `chore`: Build process or tool changes

### Scopes

**Required**: Always use a scope to provide context about what part of the codebase is affected.

#### Primary Scopes
- `content`: Blog posts, articles, and any content files
- `ui`: UI components, styling, and user interface changes
- `api`: API endpoints, server-side logic, and external integrations
- `config`: Configuration files (astro.config.ts, tsconfig.json, etc.)
- `scripts`: Build scripts, automation tools, and CLI utilities
- `deps`: Package dependencies and version updates

#### Feature-specific Scopes
- `blog`: Blog-specific functionality and components
- `search`: Search functionality and Pagefind integration
- `github`: GitHub API integration and related features
- `spotify`: Spotify integration and now-playing widget
- `markdown`: Markdown processing, plugins, and rendering

#### Technical Scopes
- `types`: TypeScript type definitions and interfaces
- `utils`: Utility functions and helper modules
- `styles`: Global styles, Tailwind configuration, and CSS
- `build`: Build process, bundling, and deployment
- `seo`: SEO optimization and meta tags

#### Rules for Scope Usage
1. **Mandatory**: Every commit must include a scope
2. **Specificity**: Use the most specific scope available
3. **Single scope**: Use only one scope per commit
4. **Consistency**: Stick to predefined scopes; avoid creating new ones
5. **Feature over technical**: Prefer feature-specific scopes when applicable

### Examples

```bash
feat(content): add new blog post about TypeScript best practices
fix(ui): resolve responsive layout issue on mobile devices
docs(config): update installation instructions in README
perf(api): optimize image loading performance
refactor(blog): extract reusable button component
chore(deps): update Astro to v5.12.3
feat(search): implement fuzzy search with Pagefind
fix(spotify): handle API rate limiting gracefully
style(markdown): improve code block syntax highlighting
feat(github): add contribution calendar widget
```

## Pre-commit Checklist

Before committing, ensure:

1. Run `pnpm check` - TypeScript and Astro validation
2. Run `pnpm lint:fix` - Auto-fix code style issues
3. Test the build with `pnpm build`
4. Verify content renders correctly

## Special Considerations

- **Content changes**: Always update content hash when modifying blog posts
- **Breaking changes**: Add `!` after type (e.g., `feat!: change API response format`)
- **Multiple changes**: Create separate commits for different types of changes
- **Large refactors**: Break into smaller, logical commits

## GitHub Integration

- Reference issues with `#123` in commit message
- Use `Closes #123` for automatic issue closing
- Add co-authors when pair programming:
  ```
  Co-authored-by: Name <email@example.com>
  ```
