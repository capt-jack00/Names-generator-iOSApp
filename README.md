# Names Generator

iOS app for generating names, built with SwiftUI.

> Status: early development — project scaffold only.

## Requirements

- Xcode 27 or later
- iOS 26.0+ deployment target
- Swift 5

## Getting started

```bash
git clone <repo-url>
cd Names-generator
open Names-generator.xcodeproj
```

Select an iOS simulator and press **⌘R** to build and run.

## Project structure

```
Names-generator/
├── Names-generator/              # App sources
│   ├── Names_generatorApp.swift  # App entry point
│   ├── ContentView.swift         # Root view (layout only)
│   ├── Models/                   # SwiftData models
│   ├── ViewModels/               # App logic / functionality
│   ├── Styles/                   # Reusable view modifiers (styling)
│   └── Assets.xcassets           # Colors, app icon
└── Names-generator.xcodeproj     # Xcode project
```

## Features

_Planned — to be defined._

## Contributing

1. Create a branch from `main`: `git checkout -b feature/<name>`
2. Commit changes following the commit convention below.
3. Open a pull request against `main`.

### Commit convention

Commits follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<optional scope>): <short summary>

<optional body: what changed and why>

<optional footer>
```

- **Summary**: imperative mood ("add", not "added"), lowercase, no period, ≤50 chars.
- **Body**: explain *what* and *why*, wrap at 72 chars. Skip for trivial changes.
- **Footer**: `BREAKING CHANGE: ...`, issue refs, co-authors.

| Type       | Use for                                               |
|------------|-------------------------------------------------------|
| `feat`     | New feature for the user                              |
| `fix`      | Bug fix                                               |
| `refactor` | Code change that neither fixes a bug nor adds feature |
| `style`    | Visual/UI styling (colours, fonts, spacing)           |
| `docs`     | Documentation only                                    |
| `test`     | Adding or updating tests                              |
| `chore`    | Tooling, config, dependencies, project settings       |
| `perf`     | Performance improvement                               |

Optional scopes: `ui`, `data`, `model`, `logic`, `project`.

Examples:

```
feat(data): store names in SwiftData
fix(ui): prevent adding empty names
refactor(logic): move duplicate check into view model
```

A commit message template is included. Enable it once per clone:

```bash
git config commit.template .gitmessage
```
