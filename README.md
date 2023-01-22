# Bible Gateway to Markdown Script

This script uses [BibleGateway.com](http://BibleGateway.com/)'s wonderful passage lookup tool to find a passage and turn it into Markdown usable in other ways.

The Markdown output includes:
- passage reference
- version abbreviation
- sub-headings
- passage text

Optionally it also includes:
- verse (and chapter) numbers
- footnotes
- cross-references
- copyright info

The output is displayed in the terminal and also gets copied to the clipboard.

When the 'Lord' is shown with small caps in the Old Testament, it is output as 'LORD'.

When the original is shown red letter (i.e. the words of Jesus), this can be rendered in bold in the Markdown output, with the `--boldwords` option.

Some versions (e.g. LEB) include some words in _italics_. This is maintained in the markdown output, though where there is a reason for the italicisation available, that isn't kept. (There would be too much of it ...)

Chapters and verses can optionally be prefixed with markdown H5 and H6 headers respectively, using the `--newline` option.

## Installation
Check you have installed the necessary gems (`colorize`, `optparse`, and `clipboard`) -- for example run `gem install colorize` or `sudo gem install colorize` etc.).

Add the .rb script to your PATH, and then set it as executable (`chmod 755 bg2md.rb`).

## Running the Script
### From the command line
Usage: `bg2md [options] reference`

(or, depending on your ruby installation, `ruby bg2md.rb [options] reference`)

The output is **displayed** in the terminal and also gets copied to the **clipboard**. 

It passes 'reference' through to the BibleGateway parser to work out what range of verses should be included. This gives lots of flexibility, for example `Jn 3.16`, `John 3:16` and `jn3:16` all return the same verse. The reference term is concatenated to remove spaces, meaning it doesn't need to be 'quoted' on the command line. You can specify a verse range e.g. `Jn 3.16-17` or even across chapters, e.g. `1 Cor 12.31-13.13`. NB: This does not yet support multiple separate passages; instead just run for each passage separately.

The following options are available:

Option | Option (longer form) | Meaning
--------- | ------------ | ---------------------------------
-b | --boldwords  |  Make the words of Jesus be shown in bold
-c | --copyright  |  Exclude copyright notice from output
-e | --headers |  Exclude editorial headers from output
-f | --footnotes  |  Exclude footnotes from output
-h | --help  | Show help
-i | --info |  Show information as I work
-l | --newline | Start chapters and verses on a new line that starts with an H5 or H6 heading
-n | --numbering  | Exclude verse and chapter numbers from output
-r | --crossrefs  |  Exclude cross-refs from output
-t | --test FILENAME  | Pass HTML from FILENAME instead of live lookup. 'reference' must still be given, but will be ignored.
-v | --version VERSION | Select Bible version to lookup using BibleGateway's abbreviations (default:NET)

### Writing to Markdown files
If you want to write to a markdown note in the current directory, then use ``bg2md.rb [options] reference > notename.md`. For example this is how I tend to run it:

`bg2md -b -c -e -r -v NIV Jn 3.16-17 > passage.md`

### From Launchers
With a little configuration it's possible to run this from Alfred or Raycast or other launchers, through whatever mechanism they use to 'Run script' with a query argument as the Bible reference. You'll likely need to create slightly different configurations for each Bible translation that you use.

## Important Disclaimers
- This is not affiliated to, or approved by, BibleGateway.com
- It's to be used in place of the very common usage of lookup-and-then-copy-and-paste the Bible text into a word processor
- The web pages produced by BibleGateway.com are full of cruft: less than 5% is typically the actual Bible text.
- The internal structure of the Bible text returned varies significantly from version to version. It also changes from time to time without notice. So if things look odd, it may be because there has been a periodic change which I'm not yet aware of.
- This is only tested on a few significant English versions that I use myself (NIV, NIVUK, NLT, ESV, MSG).
- I've not done any Internationalisation of this; I don't have the experience, but I'm willing to be helped by others here.

## Supporting you
If you spot problems, or have requests for improvement, please raise an issue at the [bg2md GitHub repository](https://www.github.com/jgclark/BibleGateway-to-Markdown). Please give details on what calls you make, and what OS and version you're using, and the version of the ruby install.

## Supporting me
If you would like to support my late-night work writing useful scripts, you can through

[<img width="200px" alt="Buy Me A Coffee" src="https://www.buymeacoffee.com/assets/img/guidelines/download-assets-sm-2.svg">](https://www.buymeacoffee.com/revjgc)

Thanks!

## History
Please see the [CHANGELOG](CHANGELOG.md).
