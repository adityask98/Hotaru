# Code Formatting & Linting Setup

This project uses **SwiftLint** and **SwiftFormat** for code quality and consistency.

## Overview

- **SwiftFormat**: Automatically formats code on every build
- **SwiftLint**: Checks code style and shows warnings/errors in Xcode

Both tools run automatically as Xcode build phases and use the configuration files checked into the repository.

## Installation

Team members need to install the tools via Homebrew:

```bash
brew install swiftlint swiftformat
```

That's it! The Xcode project is already configured to use these tools.

## How It Works

### Automatic Formatting (SwiftFormat)
- Runs on every build **before** compilation
- Automatically formats all Swift files in the `Firefly` directory
- Configuration: `.swiftformat` file in project root
- Uses 4-space indentation, 120 char line width, and consistent spacing

### Linting (SwiftLint)
- Runs on every build **during** compilation
- Shows warnings and errors in Xcode's Issue Navigator
- Configuration: `.swiftlint.yml` file in project root
- Includes opt-in rules for better code quality

## Manual Usage

### Format all files manually:
```bash
swiftformat .
```

### Check formatting without changes:
```bash
swiftformat --lint .
```

### Run SwiftLint manually:
```bash
swiftlint
```

### Auto-fix some SwiftLint issues:
```bash
swiftlint --fix
```

## Configuration Files

- **`.swiftformat`**: SwiftFormat rules (formatting style)
- **`.swiftlint.yml`**: SwiftLint rules (code quality checks)
- **`.gitignore`**: Excludes linter caches from git

All configuration files are committed to the repository, ensuring consistent formatting across the team.

## Customization

To modify the rules:
1. Edit `.swiftformat` or `.swiftlint.yml`
2. Commit the changes
3. All team members will automatically use the new rules

## Troubleshooting

### "SwiftFormat not installed" warning
Install SwiftFormat: `brew install swiftformat`

### "SwiftLint not installed" warning
Install SwiftLint: `brew install swiftlint`

### Tools not found after installation
If installed via Homebrew but not found, ensure Homebrew's bin directory is in your PATH:
```bash
# For Apple Silicon Macs
export PATH="/opt/homebrew/bin:$PATH"

# For Intel Macs
export PATH="/usr/local/bin:$PATH"
```

The build scripts already handle this automatically for both architectures.

## Build Phases

The project includes two build phases:
1. **SwiftFormat** (runs first) - Formats code
2. **SwiftLint** (runs second) - Checks code quality

These are configured in the Xcode project and run automatically on every build.
