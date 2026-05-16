# Agents

This document defines agent behavior and workflows for this project.

## Changelog Update Rule

**Whenever code changes are made (code modifications, refactoring, bug fixes, new features, etc.), the agent MUST同步 update CHANGELOG.md at the same time.**

### Changelog Entry Format

Each entry should follow this format:

```markdown
## [version] - YYYY-MM-DD

### Added
- 新功能描述

### Changed
- 已有功能的变更

### Fixed
- bug 修复描述
```

### When to Update

- After completing any code change (feature, fix, refactor)
- After any PR merge
- Before building/releasing a new version

### Version Numbering

- Patch version (`x.y.Z`): Bug fixes, small changes
- Minor version (`x.Y.0`): New features, backward compatible
- Major version (`X.0.0`): Breaking changes

### Example

Before: `## [1.2.0] - 2026-05-16`

```markdown
## [1.2.0] - 2026-05-16

### Added
- feat: 新增 xxx 功能

### Fixed
- fix: 修复了 xxx 问题
```

## Code Modification Workflow

1. Understand the task and spec requirements
2. Make code changes
3. Run tests to verify
4. Update CHANGELOG.md with the changes
5. Update spec documentation if needed
6. Commit with descriptive message
