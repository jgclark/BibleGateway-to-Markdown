#!/usr/bin/ruby
#----------------------------------------------------------------------------------
# BibleGateway passage lookup and parser to Markdown
# (c) Jonathan Clark, v0.9.1, 17.4.2020
#----------------------------------------------------------------------------------
# Uses BibleGateway.com's passage lookup tool to find
# a passage and turn into Markdown usable in other ways.
#
# It passes 'reference' through to the BibleGateway parser to work out what range
# of verses should be included.
#
# The Markdown output includes:
# - passage reference
# - version abbreviation
# - sub-headings
# - passage text
# Optionally also:
# - verse (and chapter) numbers
# - footnotes
# - copyright info
# The output also gets copied to the clipboard
#----------------------------------------------------------------------------------
# TODO:
# * [ ] Fix chapternum spacing
# * [ ] Decide whether to support returning more than one passage (e.g. "Mt1.1;Jn1.1")
# * [x] Allow version option's input string
# * [x] Copy output to clipboard
# * [x] Fix versenums in Jude
# * [x] Use original numbering for footnotes
# * [x] Cope with chapter numbering
#----------------------------------------------------------------------------------
# Ruby Strong manipulation docs: https://ruby-doc.org/core-2.7.1/String.html#method-i-replace
#----------------------------------------------------------------------------------
# Key parts of HTML Page structure currently returned by BibleGateway:
# - lots of header guff until <body ...
# - then lots of menu, login, version and search options
# - then more options
# - finally nearly 1500 lines in ...
# - <h1 class="passage-display">  (normally, but not in Jude)
# - <span class="passage-display-bcv">John 3:1-3</span>  ...
# - <span class="passage-display-version">New English Translation (NET Bible)</span></h1>
# - <h3><span id="en-NET-26112" class="text John-3-1">Conversation with Nicodemus</span></h3> ...
#     <p class="chapter-1"><span class="text John-3-1"><span class="chapternum">3 </span> ...
#     <sup data-fn='...' class='footnote' ... >
#     Pharisee<sup data-fn='#fen-NET-26112a' class='footnote' data-link='[&lt;a href=&quot;#fen-NET-26112a&quot; title=&quot;See footnote a&quot;&gt;a&lt;/a&gt;]'>[<a href="#fen-NET-26112a" title="See footnote a">a</a>]</sup> named Nicodemus, who was a member of the Jewish ruling council,<sup data-fn='#fen-NET-26112b' class='footnote' data-link='[&lt;a href=&quot;#fen-NET-26112b&quot; title=&quot;See footnote b&quot;&gt;b&lt;/a&gt;]'>[<a href="#fen-NET-26112b" title="See footnote b">b</a>]</sup> </span> <span id="en-NET-26113" class="text John-3-2"><sup class="versenum">2 </sup>came to Jesus<sup data-fn='#fen-NET-26113c' class='footnote' data-link='[&lt;a href=&quot;#fen-NET-26113c&quot; title=&quot;See footnote c&quot;&gt;c&lt;/a&gt;]'>[<a href="#fen-NET-26113c" title="See footnote c">c</a>]</sup> at night<sup data-fn='#fen-NET-26113d' class='footnote' data-link='[&lt;a href=&quot;#fen-NET-26113d&quot; title=&quot;See footnote d&quot;&gt;d&lt;/a&gt;]'>[<a href="#fen-NET-26113d" title="See footnote d">d</a>]</sup> and said to him, “Rabbi, we know that you are a teacher who has come from God. For no one could perform the miraculous signs<sup data-fn='#fen-NET-26113e' class='footnote' data-link='[&lt;a href=&quot;#fen-NET-26113e&quot; title=&quot;See footnote e&quot;&gt;e&lt;/a&gt;]'>[<a href="#fen-NET-26113e" title="See footnote e">e</a>]</sup> that you do unless God is with him.” </span> <span id="en-NET-26114" class="text John-3-3"><sup class="versenum">3 </sup>Jesus replied,<sup data-fn='#fen-NET-26114f' class='footnote' data-link='[&lt;a href=&quot;#fen-NET-26114f&quot; title=&quot;See footnote f&quot;&gt;f&lt;/a&gt;]'>[<a href="#fen-NET-26114f" title="See footnote f">f</a>]</sup> “I tell you the solemn truth,<sup data-fn='#fen-NET-26114g' class='footnote' data-link='[&lt;a href=&quot;#fen-NET-26114g&quot; title=&quot;See footnote g&quot;&gt;g&lt;/a&gt;]'>[<a href="#fen-NET-26114g" title="See footnote g">g</a>]</sup> unless a person is born from above,<sup data-fn='#fen-NET-26114h' class='footnote' data-link='[&lt;a href=&quot;#fen-NET-26114h&quot; title=&quot;See footnote h&quot;&gt;h&lt;/a&gt;]'>[<a href="#fen-NET-26114h" title="See footnote h">h</a>]</sup> he cannot see the kingdom of God.”<sup data-fn='#fen-NET-26114i' class='footnote' data-link='[&lt;a href=&quot;#fen-NET-26114i&quot; title=&quot;See footnote i&quot;&gt;i&lt;/a&gt;]'>[<a href="#fen-NET-26114i" title="See footnote i">i</a>]</sup> </span> </p>
# - <h4>Footnotes:</h4>
#   - <li id="..."><a href="#id" title="Go to John 3:1">John 3:1</a> <span class='footnote-text'>..text....</span></li>
# - <div class="publisher-info-bottom with-single">...<a href="...">New English Translation</a> (NET)</strong> <p>NET Bible® copyright ©1996-2017 by Biblical Studies Press, L.L.C. http://netbible.com All rights reserved.</p></div></div>
#----------------------------------------------------------------------------------

# require 'uri' # for dealing with URIs
require 'net/http' # for handling URIs and requests. More details at https://ruby-doc.org/stdlib-2.7.1/libdoc/net/http/rdoc/Net/HTTP.html
require 'optparse' # more details at https://docs.ruby-lang.org/en/2.1.0/OptionParser.html 'gem install OptionParser'
require 'colorize' # 'gem install colorize'
require 'clipboard' # for writing to clipboard

# Setting variables to tweak
DEFAULT_VERSION = 'NET'.freeze

# Regular expressions used to detect various parts of the HTML to keep and use
START_READ_CONTENT_RE = '<div class="passage-text">'.freeze
END_READ_CONTENT_RE   = '<\/table>$'.freeze
REF_RE = '<span class="passage-display-bcv">.*?<\/span>'.freeze
MATCH_REF_RE = '<span class="passage-display-bcv">(.*?)<\/span>'.freeze
VERSION_RE = '<span class="passage-display-version">.*?<\/span>'.freeze
MATCH_VERSION_RE = '<span class="passage-display-version">(.*?)<\/span>'.freeze
PASSAGE_RE = '<h1 class="passage-display">.*(<\/p>\s*<\/div>|<\/p>\s*<div class="footnotes">)'.freeze
MATCH_PASSAGE_RE = '(<h1 class="passage-display">.*(<\/p>\s*<\/div>|<\/p>\s*<div class="footnotes">))'.freeze
FOOTNOTE_RE = '<span class=\'footnote-text\'>.*?<\/span>'.freeze
MATCH_FOOTNOTE_RE = 'title=.*?>(.*?)<\/a>( )<span class=\'footnote-text\'>(.*)<\/span><\/li>'.freeze
COPYRIGHT_STRING_RE = '<div class="publisher-info'.freeze
MATCH_COPYRIGHT_STRING_RE = '<p>(.*)<\/p>'.freeze

#=======================================================================================
# Main logic
#=======================================================================================

# Setup program options
opts = {}
opt_parser = OptionParser.new do |o|
  o.banner = 'Usage: bg2md.rb [options] reference'
  o.separator ''
  opts[:copyright] = true
  o.on('-c', '--copyright', 'Exclude copyright notice') do
    opts[:copyright] = false
  end
  opts[:headers] = true
  o.on('-e', '--headers', 'Exclude editorial headers') do
    opts[:headers] = false
  end
  opts[:footnotes] = true
  o.on('-f', '--footnotes', 'Exclude footnotes') do
    opts[:footnotes] = false
  end
  o.on('-h', '--help', 'Show help') do
    puts o
    exit
  end
  opts[:verbose] = false
  o.on('-i', '--info', 'Show information as I work') do
    opts[:verbose] = true
  end
  opts[:numbering] = true
  o.on('-n', '--numbering', 'Exclude verse and chapter numbers') do
    opts[:numbering] = false
  end
  opts[:filename] = ''
  o.on('-t', '--test FILENAME', "Pass HTML from FILENAME instead of live lookup. 'reference' must still be given, but will be ignored.") do | f |
    opts[:filename] = f
  end
  opts[:version] = DEFAULT_VERSION
  o.on('-v', '--version VERSION', 'Select Bible version to lookup (default:' + DEFAULT_VERSION + ')') do | v |
    opts[:version] = v
  end
end
opt_parser.parse! # parse out options, leaving file patterns to process

# Get reference(s) given on command lin
ref = ARGV[0]  # or ARGV.join(';') to return multiple passages
if ref.nil?  # or ref.empty?
  puts 'Error: no reference(s) included. Stopping.'
  exit
end

# Form URL string to do passage lookup
uri = URI "https://www.biblegateway.com/passage/"
params = { interface: 'print', version: opts[:version], search: ref }
uri.query = URI.encode_www_form params

# Read the full page contents, but only save the very small interesting part
begin
  if opts[:filename].empty?
    # NOT TESTING: Call BG and check response is OK
    puts "Calling URL <#{uri}> ...".colorize(:yellow) if opts[:verbose]
    response = Net::HTTP.get_response(uri)
    case response
    when Net::HTTPSuccess then
      f = response.body.split(/\R/)
      n = 0
      input_lines = []
      indent_spaces = ''
      in_interesting = false
      f.each do |line|
        # see if we've moved into the interesting part
        if line =~ /#{START_READ_CONTENT_RE}/
          in_interesting = true
          # create 'indent_spaces' with the number of whitespace characters the first line is indented by
          line.scan(/^(\s*)/) { |m| indent_spaces = m.join }
        end
        # see if we've moved out of the interesting part
        in_interesting = false if line =~ /#{END_READ_CONTENT_RE}/
        next unless in_interesting

        # save this line, having chopped off the 'indent' amount of leading whitespace,
        # and checked it isn't empty
        updated_line = line.delete_prefix(indent_spaces).chomp
        next if updated_line.empty?

        input_lines[n] = updated_line
        n += 1
      end
      input_line_count = n
    else
      puts "--> Error: #{response.message} (#{response.code})".colorize(:red)
      exit
    end
  else
    # TESTING: read from local HTML file instead
    n = 0
    input_lines = []
    indent_spaces = ''
    in_interesting = false
    f = File.open(opts[:filename], 'r', encoding: 'utf-8')
    f.each_line do |line|
      # see if we've moved into the interesting part
      if line =~ /#{START_READ_CONTENT_RE}/
        in_interesting = true
        # create 'indent_spaces' with the number of whitespace characters the first line is indented by
        line.scan(/^(\s*)/) { |m| indent_spaces = m.join }
      end
      # see if we've moved out of the interesting part
      in_interesting = false if line =~ /#{END_READ_CONTENT_RE}/
      next unless in_interesting

      # save this line, having chopped off the 'indent' amount of leading whitespace,
      # and checked it isn't empty
      updated_line = line.delete_prefix(indent_spaces).chomp
      next if updated_line.empty?

      input_lines[n] = updated_line
      n += 1
    end
    input_line_count = n
  end
end
puts "Found #{input_line_count} interesting lines" if opts[:verbose]

# Join adjacent lines together except where it starts with a <h1 ..>, <ol>, <li ..>
working_lines = []
working_lines[0] = input_lines[0] # jump start this
w = 0
n = 1
while n < input_line_count
  line = input_lines[n]
  # puts line.colorize(TextColour) if opts[:verbose]
  if line.lstrip =~ /(<h1|<ol|<li|<div class="publisher-info)/ # often there are modifiers before closing '>'
    w += 1
    working_lines[w] = line
  else
    working_lines[w] = working_lines[w] + ' ' + line.lstrip
  end
  n += 1
end
working_line_count = w + 1
puts "Now reduced to #{working_line_count} working lines:" if opts[:verbose]

# Now read through the saved lines, saving out the various component parts
full_ref = ''
copyright = ''
passage = ''
version = ''
footnotes = []
number_footnotes = 0 # NB: counting from 0
n = 0 # NB: counting from 1
while n < working_line_count
  line = working_lines[n]
  puts line.colorize(:green) if opts[:verbose]
  # Extract full reference
  line.scan(/#{MATCH_REF_RE}/) { |m| full_ref = m.join } if line =~ /#{REF_RE}/
  # Extract version title
  line.scan(/#{MATCH_VERSION_RE}/) { |m| version = m.join } if line =~ /#{VERSION_RE}/
  # Extract passage (should be)
  line.scan(/#{MATCH_PASSAGE_RE}/) { |m| passage = m.join } if line =~ /#{PASSAGE_RE}/
  # Extract copyright
  line.scan(/#{MATCH_COPYRIGHT_STRING_RE}/) { |m| copyright = m.join } if line =~ /#{COPYRIGHT_STRING_RE}/
  # Extract footnote
  if line =~ /#{FOOTNOTE_RE}/
    line.scan(/#{MATCH_FOOTNOTE_RE}/) do |m|
      footnotes[number_footnotes] = m.join
      number_footnotes += 1
    end
  end
  n += 1
end
puts if opts[:verbose]

# Only continue if we have found the passage
puts 'Error: cannot parse passage text, so stopping.'.colorize(:red) if passage.empty?
# Now process the main passage text
# ignore <h1> as it doesn't always appear (e.g. Jude)
passage.gsub!(%r{<h1.*?</h1>\s*}, '')
# ignore all <h2>book headings</h2>
passage.gsub!(%r{<h2>.*?</h2>}, '')
# replace &nbsp; elements with simpler spaces
passage.gsub!(/&nbsp;/, ' ')
# simplify verse/chapters numbers (or remove entirely if that option set)
if opts[:numbering]
  passage.gsub!(%r{<sup class="versenum">(.*?)\s*</sup>}, '\1 ')
  # verse number '1' omitted if start of a new chapter, and the chapter number is given
  passage.gsub!(%r{<span class="chapternum">(\d+)\s*</span>}, '\1:1 ') # @@@
else
  passage.gsub!(%r{<sup class="versenum">.*?</sup>}, '')
  passage.gsub!(%r{<span class="chapternum">.*?</span>}, '')
end
# Modify various things to their markdown equivalent
passage.gsub!(/<p.*?>/, "\n") # needs double quotes otherwise it doesn't turn this into newline
passage.gsub!(%r{</p>}, '')
passage.gsub!(/<h3.*?>\s*/, "\n\n## ")
passage.gsub!(%r{</h3>}, '')
passage.gsub!(/<b>/, '**')
passage.gsub!(%r{</b>}, '**')
passage.gsub!(%r{<i>}, '_')
passage.gsub!(%r{</i>}, '_')
passage.gsub!(%r{<br />}, "  \n") # use two trailling spaces to indicate line break but not paragraph break
# simplify footnotes (or remove if that option set). Complex so do in several stages.
if opts[:footnotes]
  passage.gsub!(/<sup data-fn=\'.*?>/, '<sup>')
  passage.gsub!(%r{<sup>\[<a href.*?>(.*?)</a>\]</sup>}, '[^\1]')
else
  passage.gsub!(%r{<sup data-fn.*?<\/sup>}, '')
end
# replace <a>...</a> elements with simpler [...]
passage.gsub!(/<a .*?>/, '[')
passage.gsub!(%r{</a>}, ']')
# take out some <div> and </div> elements
passage.gsub!(/<div class="footnotes">/, '')
passage.gsub!(/<div class="poetry.*?>/, '')
passage.gsub!(%r{\s*</div>}, '')
# take out all <span> and </span> elements (needs to come after chapternum spans)
passage.gsub!(/<span .*?>/, '')
passage.gsub!(%r{</span>}, '')

# If we want footnotes, process each footnote item, simplifying
if number_footnotes.positive?
  i = 0
  footnotes.each do |ff|
    # Change all <b>...</b> to *...* and <i>...</i> to _..._
    ff.gsub!(/<b>/, '**')
    ff.gsub!(%r{</b>}, '**')
    ff.gsub!(/<i>/, '_')
    ff.gsub!(%r{</i>}, '_')
    # replace all <a class="bibleref" ...>ref</a> with [ref]
    ff.gsub!(/<a .*?>/, '[')
    ff.gsub!(%r{</a>}, ']')
    # Remove all <span>s around other languages
    ff.gsub!(/<span .*?>/, '')
    ff.gsub!(%r{</span>}, '')
    footnotes[i] = ff
    i += 1
  end
end

# Create an alphabetical hash of numbers (Mod 26) to mimic their
# footnote numbering scheme. Taken from
# https://stackoverflow.com/questions/14632304/generate-letters-to-represent-number-using[math - Generate letters to represent number using ruby? - Stack Overflow](https://stackoverflow.com/questions/14632304/generate-letters-to-represent-number-using-ruby)
h = {}
('a'..'zz').each_with_index { |w, i| h[i + 1] = w }

# Finally, prepare the output
output_text = "# #{full_ref} (#{version})\n"
output_text += "#{passage}\n\n"
if number_footnotes.positive? && opts[:footnotes]
  output_text += "### Footnotes\n"
  i = 1
  footnotes.each do |ff|
    output_text += "[^#{h[i]}]: #{ff}\n"
    i += 1
  end
  output_text += "\n"
end
output_text += copyright.to_s if opts[:copyright]

# Then write out text to screen
puts
puts output_text
Clipboard.copy(output_text)
