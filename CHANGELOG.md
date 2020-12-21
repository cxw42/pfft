# Changelog for pfft

All notable changes to the [pfft] lightweight Markdown-to-PDF converter will be
documented in this file.

The format of this changelog is based on
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The notation "(DEV)" marks changes of interest primarily to developers
as opposed to users.

Categories are:

- "Added": new features.
- "Changed": changes in existing functionality.
- "Deprecated": soon-to-be removed features.
- "Removed": features removed as of the version they are listed in.
- "Fixed": bug fixes.
- "Security": updates fixing vulnerabilities.

## [Unreleased]

### Fixed

- Images that are too wide for the page will be scaled down to fit (#32)

## [0.0.6] - 2020-12-06

### Added

- This file!
- Special blocks are now supported in core (#7)
- md4c-reader: special blocks can themselves include Markdown (#23)
- You can now use HTML comments in your Markdown files --- md4c-reader
  and pango-markup cooperate to remove those comments from the output (#28)

### Fixed

- pango-markup: Code blocks within bulleted or numbered lists are indented
- pango-markup: Consecutive headers have whitespace between them (#29)

## [0.0.5] - 2020-11-21

### Added

- pango-markup: Any image in a paragraph by itself, with a caption, will be rendered as a centered figure with that caption (#22)
- md4c-reader: Accept GitHub-flavored Markdown and underlines.  Now `*italics*` and `_underline_`, instead of `_italics_`
- (DEV) Can now generate Debian packages (#12)

### Changed

- pango-markup: 12-point fonts are actually 12 points now (they were larger before) (8cbb1be5a221168bab6f48dc98d06af53d6cc3a5)
- pango-markup: Code blocks now have light-gray backgrounds so they stand out more (#3)
- (DEV) Minimum valac now 0.48
  - Use valac from the [Vala Next PPA](https://launchpad.net/~vala-team/+archive/ubuntu/next) on Travis

## [0.0.4] - 2020-10-31

### Added

- You can now specify a font name
- You can now specify left/center/right justification.  (It currently applies to everything, which makes lists look a bit strange!)

### Changed

- pango-markup: Paragraphs of body text now have whitespace between them

## [0.0.3] - 2020-09-26

### Added

- You can now set the font size
- You can use dimensions in templates, e.g., `210mm` instead of `8.2677` (inches)

### Changed

- (DEV) Much-improved test coverage
- (DEV) Lightly-improved CONTRIBUTING.md

## [0.0.2] - 2020-09-07

### Added

- Add `--template` to load a `.pfft` file specifying page size, margins, and header/footer text (#9)
- Add `--quiet`
- (DEV) Check code coverage
- (DEV) On successful Travis builds, report coverage to codecov.io

### Changed

- Convert logging to GStreamer.  Now you can say `GST_DEBUG='pfft:N'` to set the debug level to `N` (0=none, 9=way too much)
- (DEV) Add lots more tests

## [0.0.1] - 2020-08-29

### Added

- Read Markdown files containing headers, code blocks, images, lists
- Render PDFs

[Unreleased]: https://github.com/cxw42/pfft/compare/v0.0.6...HEAD
[0.0.6]: https://github.com/cxw42/pfft/compare/v0.0.5...v0.0.6
[0.0.5]: https://github.com/cxw42/pfft/compare/v0.0.4...v0.0.5
[0.0.4]: https://github.com/cxw42/pfft/compare/v0.0.3...v0.0.4
[0.0.3]: https://github.com/cxw42/pfft/compare/v0.0.2...v0.0.3
[0.0.2]: https://github.com/cxw42/pfft/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/cxw42/pfft/compare/cc7632e090218a32fb631734d1eb0e39adfdf173...v0.0.1

[pfft]: https://github.com/cxw42/pfft
