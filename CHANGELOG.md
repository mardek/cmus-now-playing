# Changelog

All notable changes to cmus-now-playing are documented in this file.

## [Unreleased]

### Added

- Interactive full-screen dashboard with current-track details and play history.
- Compact history view and keyboard controls for playback, navigation, seeking,
  shuffle, and volume.
- Persistent terminal status bar with playback progress and system volume.
- Built-in `--install` option with configurable `PREFIX` installation directory.
- Public GitHub download and installation instructions.
- BSD 2-Clause license file.

### Changed

- Preserve long and wrapped history entries inside the terminal viewport.
- Use a slimmer status-bar progress indicator.
- Restore the dark dashboard background so its original foreground palette
  remains readable with light terminal themes.

### Removed

- Separate `install.sh`; installation is handled by the main script.
- Formatter-specific tests and options that do not apply to the interactive
  Zsh dashboard.
