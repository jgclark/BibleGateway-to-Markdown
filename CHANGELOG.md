# CHANGELOG

### v1.4.4, 11.1.2022
- [Change] Add reference to this project in the help text.

### v1.4.3, 12.11.2021
- [Change] Show help text if no reference is given at the command line.

### v1.4.2, 5.11.2021
- [Fix] Fix so that script will use user's selected Ruby installation, rather than the default one, which at least on macOS is very out-dated.

### v1.4.1, 28.5.2021
- [Fix] Fixed Crossref markers were being truncated to a single character after the 26th Crossref.

### v1.4.0, 1.2.2021
- [Change/New] Add `--boldwords` option to turn on Markdown bold for the words of Jesus. This is now off by default.
- [New] Add `--newline` option to start chapters and verses on a new line that starts with an H5 or H6 heading

### v1.3.0, 29.12.2020
- [New] Add ability to parse and show cross-references (or suppress with `-r` option), as seen in NIV and ESV versions, for example.
- [New] Handle the unusual (unique?) multi-verse numbering in the MSG version.

### v1.2.1, 2.12.2020
- [Improve] The reference term is concatenated to remove spaces, meaning it doesn't need to be 'quoted'. It does not yet support multiple passages.

### v1.2.0, 20.7.2020
- [Fix] major underlying changes to cope with significant changes at BibleGateway.com
