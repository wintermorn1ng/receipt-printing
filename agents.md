# Agents

This document defines agent behavior and workflows for this project.

## Changelog Update Rule

**Whenever code changes are made (code modifications, refactoring, bug fixes, new features, etc.), the agent MUST 同步 update CHANGELOG.md at the same time.**

### How to Update

**直接追加到当前最新版本下，不要新建版本号。** 找到 CHANGELOG.md 中最新的 `## [x.y.z] - YYYY-MM-DD` 版本条目，将本次改动追加到对应的 `### Added` / `### Changed` / `### Fixed` 分类下。

```markdown
## [1.0.1] - 2026-05-16

### Added
- feat: 已有功能A
- feat: 本次新增的功能B    ← 直接加在这里

### Fixed
- fix: 已有修复X
- fix: 本次修复的问题Y    ← 直接加在这里
```

### When to Update

- After completing any code change (feature, fix, refactor)
- Before committing

### Example

Before:
```markdown
## [1.0.1] - 2026-05-16

### Added
- feat: 支持调整网格列数
```

After (add new item under same version):
```markdown
## [1.0.1] - 2026-05-16

### Added
- feat: 支持调整网格列数
- feat: 新增 xxx 功能
```

## Code Modification Workflow

1. Understand the task and spec requirements
2. Make code changes
3. Run tests to verify
4. Update CHANGELOG.md with the changes
5. Update spec documentation if needed
6. Commit with descriptive message
