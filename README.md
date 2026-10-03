# Names Generator

iOS app for keeping a list of names and picking random ones from it, e.g. to
assign people to days of the week. Built with SwiftUI and SwiftData.

> Status: in development.

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

## Features

### Names list

- Add names with the text field (button or return key). Empty names are
  blocked, and so are names already on the list unless **Can repeat names**
  is on (compared ignoring case).
- Optional auto-capitalization: `anna-maria mcDonald` → `Anna-Maria McDonald`.
- Newest names first, each with a coloured initial badge (same colour for the
  same name every time). Swipe a row to delete it.
- **Search** finds names starting with the typed text, ignoring case and
  accents (`luk` finds `Łukasz`). It only filters the list; picking always
  uses all names.
- The list shows 10 names at a time: **Show more (+N)** reveals 10 more,
  **Show less** collapses back. A new search starts again from 10.

### Random pick

- **Pick a random name** picks names for every label (see Settings), e.g.
  `Monday: Anna, Bartek`. Without any labels, names are shown on their own;
  slots without a label show their number.
- Names that haven't been picked for a while get a higher chance.
- A name is never picked for two labels in a row, and every name is used once
  before any name repeats.
- The result can be shared as plain text.

### Settings

| Setting | What it does |
|---|---|
| Names to pick | Number of labels to pick names for (1–30, needs 2+ names) |
| Labels | Optional label per pick, e.g. `Monday`; kept when the amount shrinks |
| Names per label | Up to half of all names with 2+ labels, or names − 1 with one label |
| Can repeat names | Allow adding a name that is already on the list |
| Auto-capitalize names | Capitalize every word of added and imported names |
| Font size | Size of picked names (10–40), stepper or number pad |
| Clear names / Clear labels | Delete all names or labels after a confirmation alert |

Stored amounts are kept in range when names are deleted.

### Import from a .sql file

**Import names** reads a SQL dump (MySQL, PostgreSQL or SQLite) without
running it, then shows one menu to choose:

1. the table (only asked when the file has more than one),
2. the column(s) with names — likely name columns such as `name`,
   `full_name` or `first_name` + `last_name` are preselected; several columns
   are joined with a space,
3. how many names — all, or the first N,

with a preview of the result. Imported names follow the same rules as typed
ones: auto-capitalization, empty values skipped, duplicates skipped unless
**Can repeat names** is on.

Limitations:

- iOS has no built-in file type for `.sql`, so files are matched by extension.
- Backslashes inside quoted values are read as escapes (MySQL style).

## Project structure

```
Names-generator/
├── Names-generator/
│   ├── Names_generatorApp.swift      # App entry point, SwiftData container
│   ├── ContentView.swift             # Main screen (layout only)
│   ├── Models/
│   │   ├── NameEntry.swift           # SwiftData model of a name
│   │   └── AppSettings.swift         # Settings keys, defaults and allowed ranges
│   ├── ViewModels/
│   │   ├── NamesViewModel.swift      # Add, search, paging, pick, delete, import
│   │   ├── WeightedPicker.swift      # Weighted random picking per label
│   │   ├── PickResultFormatter.swift # "Label: names" lines and share text
│   │   ├── SQLDumpParser.swift       # Reads tables and rows from .sql files
│   │   └── NameImporter.swift        # Guesses name columns, filters imported names
│   ├── Views/
│   │   ├── SettingsView.swift        # Settings screen
│   │   ├── ImportNamesView.swift     # Import menu
│   │   ├── PickedNameCard.swift      # Pick result card
│   │   ├── NameRow.swift             # Row in the names list
│   │   └── SearchField.swift         # Search bar inside the list
│   ├── Styles/
│   │   └── ViewStyles.swift          # All view modifiers (styling)
│   └── Assets.xcassets               # Colors, app icon
└── Names-generator.xcodeproj         # Xcode project
```

### Code conventions

- **Logic** goes in `ViewModels/`; views only call it.
- **Layout** goes in `ContentView` and `Views/`; reusable components get
  their own file in `Views/`.
- **Styling** goes through view modifiers in `Styles/ViewStyles.swift`
  (e.g. `.primaryActionStyle()`), not inline in views.
- Code runs on the main actor by default (`SWIFT_DEFAULT_ACTOR_ISOLATION`).
  Heavy work, like parsing `.sql` files, is marked `nonisolated` /
  `@concurrent` to run in the background.
- There is no test target yet.

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
