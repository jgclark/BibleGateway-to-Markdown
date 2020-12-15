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

When the original is shown red letter (words of Jesus), this is rendered in bold instead.

## Installation
tbd

## Running the Script
Usage: `bg2md.rb [options] reference`

It passes 'reference' through to the BibleGateway parser to work out what range of verses should be included.

The following options are available:

- -c, --copyright    Exclude copyright notice from output
- -e, --headers   Exclude editorial headers from output
- -f, --footnotes    Exclude footnotes from output
- -h, --help   Show help
- -i, --info   Show information as I work
- -n, --numbering   Exclude verse and chapter numbers from output
- -t, --test FILENAME    Pass HTML from FILENAME instead of live lookup. 'reference' must still be given, but will be ignored.
- -v, --version VERSION    Select Bible version to lookup using BibleGateway's abbreviations (default:NET)

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
