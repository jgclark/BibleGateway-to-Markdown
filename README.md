# README

This script uses [BibleGateway.com](http://BibleGateway.com/)'s wonderful passage lookup tool to find a passage and turn it into Markdown usable in other ways.

The Markdown output includes:
- passage reference
- version abbreviation
- sub-headings
- passage text

Optionally it also includes:
- verse (and chapter) numbers
- footnotes
- copyright info

The output also gets copied to the clipboard.

When the 'Lord' is shown with small caps (in OT), it is output as 'LORD'.

When the original is shown red letter (i.e. the words of Jesus), this is rendered in bold in the Markdown output.

## Installation
Check you have installed the `colorize` and `optparse` gems (> `gem install colorize optparse`).

Add the .rb script(s) to your path, and then set them as executable (`chmod 755 np*.rb`)

## Running the Script
### From the command line
Usage: `bg2md.rb [options] reference`

It passes 'reference' through to the BibleGateway parser to work out what range of verses should be included. This gives lots of flexibility, for example `Jn 3.16`, `John 3:16\` and `jn3:16` all return the same verse. The reference term is concatenated to remove spaces, meaning it doesn't need to be 'quoted' on the command line. You can specify a verse range e.g. `Jn 3.16-17` or even across chapters, e.g. `1 Cor 12.31-13.13`. NB: This does not yet support multiple separate passages; instead just run for each passage separately.

The following options are available:

Option | Option (longer form) | Meaning
--------- | ------------ | ---------------------------------
-c | --copyright  |  Exclude copyright notice from output
-e | --headers |  Exclude editorial headers from output
-f | --footnotes  |  Exclude footnotes from output
-h | --help  | Show help
-i | --info |  Show information as I work
-n | --numbering  | Exclude verse and chapter numbers from output
-t | --test FILENAME  | Pass HTML from FILENAME instead of live lookup. 'reference' must still be given, but will be ignored.
-v | --version VERSION | Select Bible version to lookup using BibleGateway's abbreviations (default:NET)

### From Launchers
e.g. Alfred -- tbd

## Important Disclaimers
- This is not affiliated to, or approved by, BibleGateway.com
- It's to be used in place of the very common usage of lookup-and-then-copy-and-paste the Bible text into a word processor
- The web pages produced by BibleGateway.com are full of cruft: less than 5% is typically the actual Bible text.
- The internal structure of the Bible text returned varies significantly from version to version 
- This is only tested on a few significant English versions that I use myself
- I've not done any Internationalisation of this; I don't have the experience, but I'm willing to be helped by others here.
- The internal structure of the web pages returned from BibleGateway.com also changes from time to time. So if things look odd, it may be because there has been a periodic change which I'm not yet aware of.

## Issues, Requests
If you spot problems, or have requests for improvement, please raise an issue at the [bg2md GitHub repository](https://www.github.com/jgclark/BibleGateway-to-Markdown).
