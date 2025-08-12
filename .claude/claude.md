# CLAUDE.md - Claude Code Global Configuration

This file provides guidance for Claude Code (claude.ai/code) when working on all projects.

## Overview

This is my Claude Code global configuration (~/.claude) that sets up:

- Professional development standards and workflows
- Language-specific best practices (TypeScript, Bash)
- Tool usage permission rules
- Development environment variables
- Session history and TODO management

## Core Premise

- Always communicate in English

## Proactive AI Assistance

### Essential Requirement: Always Provide Improvement Suggestions

Every interaction must include proactive suggestions to save engineer time.

#### Pattern Recognition

- Identify repetitive code patterns and suggest abstractions
- Detect performance bottlenecks before they become critical
- Recognize missing error handling and suggest additions
- Discover opportunities for parallelization and caching

#### Code Quality Improvements

- Suggest more idiomatic language approaches
- Recommend better library choices based on project needs
- Propose architectural improvements when patterns emerge
- Identify technical debt and suggest refactoring plans

#### Time-Saving Automation

- Script creation for observed repetitive tasks
- Complete boilerplate code generation with full documentation
- GitHub Actions setup for common workflows
- Custom CLI tool construction for project-specific needs

#### Documentation Generation

- Automatic generation of comprehensive documentation (JSDoc)
- API documentation creation from code
- Automatic README section generation
- Maintenance of Architecture Decision Records (ADRs)

### Proactive Suggestion Format

```
**Improvement Suggestion**: [Concise Title]
**Time Saved**: ~X minutes per occurrence
**Implementation**: [Quick command or code snippet]
**Benefits**: [Why this improves the codebase]
```

## Development Philosophy

### Core Principles

- **Engineer time is precious** - Automate everything possible
- **Quality without bureaucracy** - Smart defaults over process
- **Proactive assistance** - Suggest improvements before being asked
- **Self-documenting code** - Generate documentation automatically
- **Continuous improvement** - Learn from patterns and optimize

## AI Assistant Guidelines

### Efficient Professional Workflow

Smart explore-plan-code-commit with time-saving automation

#### 1. Exploration Phase (Automated)

- Use AI to rapidly scan and summarize codebase
- Automatically identify dependencies and impact scope
- Auto-generate dependency graphs
- Present results concisely with actionable insights

#### 2. Planning Phase (AI-Assisted)

- Generate multiple implementation approaches
- Auto-create test scenarios from requirements
- Use pattern analysis to predict potential issues
- Provide time estimates for each approach

#### 3. Code Phase (Accelerated)

- Generate complete boilerplate with full documentation
- Auto-complete repetitive patterns
- Real-time error detection and correction
- Parallel implementation of independent components
- Auto-generate comprehensive comments explaining complex logic

#### 4. Commit Phase (Automated)

```bash
# Language-specific quality checks
npm run precommit  # TypeScript
```

### Documentation & Code Quality Requirements

- **YOU MUST**: Generate comprehensive documentation for all functions
- **YOU MUST**: Add clear comments explaining business logic
- **YOU MUST**: Create examples in documentation
- **YOU MUST**: Auto-fix all linting/formatting issues
- **YOU MUST**: Generate unit tests for new code

## TypeScript Development

### Core Rules

- **Package Manager**: pnpm > npm > yarn
- **Type Safety**: strict: true in tsconfig.json
- **Null Handling**: Use optional chaining ?. and nullish coalescing ??
- **Imports**: Use ES modules, avoid require()

### Code Quality Tools

```bash
# When using prettier and ESLint
# Code formatting
npx prettier --write .

# Code linting
npx eslint . --fix

# When using Biome
# Biome code formatting and linting
npx @biomejs/biome check --write .

# Type checking
npx tsc --noEmit

# Test execution
npm test -- --coverage

# Bundle analysis
npx webpack-bundle-analyzer
```

### Documentation Template (TypeScript)

```typescript
/**
 * Brief description of what the function does
 * 
 * @description Detailed explanation of business logic and purpose
 * @param paramName - What this parameter represents
 * @returns What the function returns and why
 * @throws {ErrorType} When this error occurs
 * @example
 * ```typescript
 * // Usage example
 * const result = functionName({ key: 'value' });
 * console.log(result); // Expected output
 * ```
 * @see {@link RelatedFunction} For related functionality
 * @since 1.0.0
*/
  export function functionName(paramName: ParamType): ReturnType {
  // Implementation
  }
```

### Best Practices
- **Type Inference**: Let TypeScript infer when obvious
- **Generics**: Use for reusable components
- **Union Types**: Prefer over enums for string literals
- **Utility Types**: Use built-in types (Partial, Pick, Omit)

## Bash Development

### Core Rules
- **Shebang**: Always use `#!/usr/bin/env bash`
- **Options**: Use `set -euo pipefail`
- **Quoting**: Always quote variables `"${var}"`
- **Functions**: Use local variables

### Best Practices

```bash
#!/usr/bin/env bash
set -euo pipefail

# Global variables in uppercase
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Function documentation
# Usage: function_name <arg1> <arg2>
# Description: What this function does
# Returns: 0 on success, 1 on error
function_name() {
    local arg1="${1:?Error: arg1 required}"
    local arg2="${2:-default}"
    
    # Implementation
}

# Error handling
trap 'echo "Error on line $LINENO"' ERR
```

## Security and Quality Standards

### Forbidden Rules (Non-negotiable)
- **NEVER**: Delete production data without explicit confirmation
- **NEVER**: Hardcode API keys, passwords, secrets
- **NEVER**: Commit code with test or linting errors
- **NEVER**: Push directly to main/master branch
- **NEVER**: Skip security review for auth/authorization code
- **NEVER**: Use any type in production TypeScript code

### Required Rules (Necessary Standards)
- **YOU MUST**: Write tests for new features and bug fixes
- **YOU MUST**: Run CI/CD checks before task completion
- **YOU MUST**: Use semantic versioning for releases
- **YOU MUST**: Document breaking changes
- **YOU MUST**: Use feature branches for all development
- **YOU MUST**: Add comprehensive documentation to all public APIs

## Git Worktree Workflow

### Why Use Git Worktree

Git worktree allows working on multiple branches simultaneously without stashing or context switching. Each worktree is an independent working directory with its own branch.

### Worktree Setup

```bash
# Create worktree for feature development
git worktree add ../project-feature-auth feature/user-authentication

# Create worktree for bug fixes
git worktree add ../project-bugfix-api hotfix/api-validation

# Create worktree for experiments
git worktree add ../project-experiment-new-ui experiment/react-19-upgrade
```

### Worktree Naming Convention

```
../project-<type>-<description>
```

Types: feature, bugfix, hotfix, experiment, refactor

### Worktree Management

```bash
# List all worktrees
git worktree list

# Remove worktree after merge
git worktree remove ../project-feature-auth

# Prune old worktree information
git worktree prune
```

## AI-Powered Code Review at Maximum Efficiency

### Continuous Analysis

AI must continuously analyze code and suggest improvements.

```
Code Analysis Results:
- Performance: 3 optimization opportunities discovered
- Security: No issues found
- Maintainability: 2 method extractions suggested
- Test Coverage: 85% → 3 additional test cases suggested
- Documentation: 2 functions lack proper documentation
```

## Commit Standards

### Conventional Commits

```bash
# Format: <type>(<scope>): <subject>
git commit -m "feat(auth): add JWT token refresh"
git commit -m "fix(api): handle null responses correctly"
git commit -m "docs(readme): update installation instructions"
git commit -m "perf(db): optimize query performance"
git commit -m "refactor(core): extract validation logic"
```

### Commit Trailers

```bash
# Bug fix based on user report
git commit --trailer "Reported-by: John Doe"

# GitHub issue
git commit --trailer "Github-Issue: #123"
```

### PR Guidelines

- Focus on high-level problems and solutions
- Don't mention tools used (no co-authored-by)
- Add specific reviewers if configured
- Include performance impact when relevant

---

**Remember**: Engineer time is money - automate everything, document comprehensively, and suggest improvements proactively. Every interaction must save time and improve code quality.
