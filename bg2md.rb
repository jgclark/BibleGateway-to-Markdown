#!/usr/bin/env ruby
#------------------------------------------------------------------------------
# BibleGateway passage lookup and parser to Markdown
# - Jonathan Clark, v1.5.0, 29.1.2024
#------------------------------------------------------------------------------
# Uses BibleGateway.com's passage lookup tool to find a passage and turn it into Markdown usable in other ways.
# It passes 'reference' through to the BibleGateway parser to work out what range of verses should be included.
# The reference term is concatenated to remove spaces, meaning it doesn't need to be 'quoted'.
# It does not yet support multiple passages.
#
# The Markdown output includes:
# - passage reference
# - version abbreviation
# - sub-headings
# - passage text
# Optionally also:
# - verse (and chapter) numbers
# - footnotes
# - cross-refs
# - copyright info
#
# The output also gets copied to the clipboard.
# When the 'Lord' is shown with small caps (in OT), it's output as 'LORD'.
# When the original is shown red letter (words of Jesus), this is rendered in bold instead.
#
# **See bg_HTML_structure.md for details of the reverse-engineered HTML structure.**
#
# In what is returned from BibleGateway it ignores:
# - all <h2> meta-chapter titles, <hr />, most <span>s
#------------------------------------------------------------------------------
# TODO: 
# - Decide whether to support returning more than one passage (e.g. "Mt1.1;Jn1.1")
#------------------------------------------------------------------------------
# Ruby String manipulation docs: https://ruby-doc.org/core-2.7.1/String.html#method-i-replace
#------------------------------------------------------------------------------
# - You can run this in -test mode, which uses a local file as the HTML input,
#   to avoid over-using the BibleGateway service.
#------------------------------------------------------------------------------
VERSION = '1.5.0'.freeze

# require 'uri' # for dealing with URIs
require 'net/http' # for handling URIs and requests. More details at https://ruby-doc.org/stdlib-2.7.1/libdoc/net/http/rdoc/Net/HTTP.html
require 'optparse' # more details at https://docs.ruby-lang.org/en/2.1.0/OptionParser.html 'gem install OptionParser'
require 'colorize' # 'gem install colorize'
require 'clipboard' # for writing to clipboard

# Setting variables to tweak
DEFAULT_VERSION = 'NET'.freeze

# Regular expressions used to detect various parts of the HTML to keep and use
START_READ_CONTENT_RE = '<h1 class=[\'"]passage-display[\'"]>'.freeze # seem to see both versions of this -- perhaps Jude is an outlier?
END_READ_CONTENT_RE   = '<section class="other-resources">|<section class="sponsors">'.freeze
# Match parts of lines which actually contain passage text
PASSAGE_RE = '(<p>\s*<span id=|<p class=|<p>\s?<span class=|<h3).*?(?:<\/p>|<\/h3>)'.freeze
# Match parts of lines which actually contain passage text -- this uses non-matching groups to allow both options and capture
MATCH_PASSAGE_RE = '((?:<p>\s*<span id=|<p class=|<p>\s?<span class=|<h3).*?(?:<\/p>|<\/h3>))'.freeze
# Match lines that give the reference and version info in a displayable form
REF_RE = '(<div class=\'bcv\'><div class="dropdown-display"><div class="dropdown-display-text">|<span class="passage-display-bcv">).*?(<\/div>|<\/span>)'.freeze
MATCH_REF_RE = '(?:<div class=\'bcv\'><div class="dropdown-display"><div class="dropdown-display-text">|<span class="passage-display-bcv">)(.*?)(?:<\/div>|<\/span>)'.freeze
VERSION_RE = '(<div class=\'translation\'><div class="dropdown-display"><div class="dropdown-display-text">|<span class="passage-display-version">).*?(<\/div>|<\/span>)'.freeze
MATCH_VERSION_RE = '(?:<div class=\'translation\'><div class="dropdown-display"><div class="dropdown-display-text">|<span class="passage-display-version">)(.*?)(?:<\/div>|<\/span>)'.freeze
FOOTNOTE_RE = '<span class=\'footnote-text\'>.*?<\/span>'.freeze
MATCH_FOOTNOTE_RE = 'title=.*?>(.*?)<\/a>( )<span class=\'footnote-text\'>(.*)<\/span><\/li>'.freeze
CROSSREF_RE = '<a class="crossref-link".*?">.*?</a></li>'.freeze
MATCH_CROSSREF_RE = '<a class="crossref-link".*?">(.*)?</a></li>'.freeze
COPYRIGHT_STRING_RE = '<div class="publisher-info'.freeze
MATCH_COPYRIGHT_STRING_RE = '<p>(.*)<\/p>'.freeze

# Request timeout when fetching from BibleGateway
FETCH_READ_TIMEOUT = 10 # Net::ReadTimeout (default is 5 seconds to establish a connection)
FETCH_OPEN_TIMEOUT = 30 # Net::OpenTimeout (default is 10 seconds to wait for a response from the server)

#==============================================================================
# Main logic
#==============================================================================

# Setup program options
opts = {}
opt_parser = OptionParser.new do |o|
  o.banner = 'Usage: bg2md.rb [options] reference'
  o.separator ''
  o.separator '  The reference should be enclosed in quotation marks if it contains spaces.'
  o.separator ''
  o.separator 'Specific options:'
  opts[:boldwords] = false
  o.on('-b', '--boldwords', 'Make the words of Jesus be shown in bold') do
    opts[:boldwords] = true
  end
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
  opts[:newline] = false
  o.on('-l', '--newline', 'Start chapters and verses on newline with H5 or H6 heading') do
    opts[:newline] = true
  end
  opts[:numbering] = true
  o.on('-n', '--numbering', 'Exclude verse and chapter numbers') do
    opts[:numbering] = false
  end
  opts[:crossrefs] = true
  o.on('-r', '--crossrefs', 'Exclude cross-references') do
    opts[:crossrefs] = false
  end
  opts[:filename] = ''
  o.on('-t', '--test FILENAME', "Pass HTML from FILENAME instead of live lookup. 'reference' must still be given, but will be ignored.") do |f|
    opts[:filename] = f
  end
  opts[:version] = DEFAULT_VERSION
  o.on('-v', '--version VERSION', 'Select Bible version to lookup (default:' + DEFAULT_VERSION + ')') do |v|
    opts[:version] = v
  end
  o.separator 'Code from https://github.com/jgclark/BibleGateway-to-Markdown/'
end
# parse out options, removing them, leaving just reference pattern(s) to process
opt_parser.parse!

# Get reference given on command line
if ARGV.empty? || ARGV[0].empty?
  puts "Error: you need to supply a reference.".colorize(:red)
  puts opt_parser # show help
  exit
else
  ref = ARGV[0]
end

# Form URL string to do passage lookup
uri = URI 'https://www.biblegateway.com/passage/'
params = { interface: 'print', version: opts[:version], search: ref }
uri_opts = { use_ssl: uri.scheme == 'https', read_timeout: FETCH_READ_TIMEOUT, open_timeout: FETCH_OPEN_TIMEOUT }
uri.query = URI.encode_www_form params

# Read the full page contents, but only save the very small interesting part
input_line_count = 0
if opts[:filename].empty?
  # If we're not running with test data: Call BG and check response is OK
  puts "Calling URL <#{uri}> ...".colorize(:yellow) if opts[:verbose]
  response = Net::HTTP.start(uri.hostname, uri.port, uri_opts) do |http|
    http.get(uri)
  end
  case response
  when Net::HTTPSuccess
    ff = response.body.force_encoding('utf-8') # otherwise returns as ASCII-8BIT ??
    f = ff.split(/\R/) # split on newline or CR LF
    n = 0
    input_lines = []
    # indent_spaces = ''
    in_interesting = false
    f.each do |line|
      # see if we've moved into the interesting part
      if line =~ /#{START_READ_CONTENT_RE}/
        in_interesting = true
        # create 'indent_spaces' with the number of whitespace characters the first line is indented by
        # line.scan(/^(\s*)/) { |m| indent_spaces = m.join }
      end
      # see if we've moved out of the interesting part
      in_interesting = false if line =~ /#{END_READ_CONTENT_RE}/
      next unless in_interesting

      # save this line, having chopped off the 'indent' amount of leading whitespace,
      # and checked it isn't empty
      updated_line = line.strip # delete_prefix(indent_spaces).chomp
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
  # If we're running with TEST data: read from local HTML file instead
  n = 0
  input_lines = []
  # indent_spaces = ''
  in_interesting = false
  puts "Using test data from '#{opts[:filename]}'...".colorize(:yellow) if opts[:verbose]
  f = File.open(opts[:filename], 'r', encoding: 'utf-8')
  f.each_line do |line|
    # see if we've moved into the interesting part
    if line =~ /#{START_READ_CONTENT_RE}/
      in_interesting = true
      # create 'indent_spaces' with the number of whitespace characters the first line is indented by
      # line.scan(/^(\s*)/) { |m| indent_spaces = m.join }
    end
    # see if we've moved out of the interesting part
    in_interesting = false if line =~ /#{END_READ_CONTENT_RE}/
    next unless in_interesting

    # save this line, having chopped off the 'indent' amount of leading whitespace,
    # and checked it isn't empty
    updated_line = line.strip # delete_prefix(indent_spaces).chomp
    next if updated_line.empty?

    input_lines[n] = updated_line
    n += 1
  end
  input_line_count = n
end

if input_line_count.zero?
  puts 'Error: the data returned from BibleGateway is empty, so stopping. Please check your usage, and if still a problem, please raise an issue on GitHub.'.colorize(:red)
  exit
end

# Join adjacent lines together
lump = input_lines[0] # jump start this
n = 1
while n < input_line_count
  line = input_lines[n]
  n += 1
  # add line to 'lump' if it's not one of hundreds of version options
  # Note: join with space, for reasons I now don't remember
  lump = lump + ' ' + line.strip if line !~ %r{<option.*</option>}
end
puts "Pass 1: 'Interesting' text = #{input_line_count} lines, #{lump.size} bytes." if opts[:verbose]

if lump.empty?
  puts 'Error: found no \'interesting\' text in BibleGateway HTML data, so stopping.'.colorize(:red)
  exit
end

# Then break apart on </h1>, </h4>, </ol>, </li>, </p> to make parsing logic easier
working_lines = []
w = 0
lump.scan(%r{(.*?(</p>|</li>|</ol>|</h1>|</h4>))}) do |m|
  break if m[0].nil?

  working_lines[w] = m[0].strip
  # puts (working_lines[w]).to_s if opts[:verbose]
  w += 1
end
working_line_count = w + 1
puts "Pass 2: Now has #{working_line_count} working lines:" if opts[:verbose]
puts working_lines.join('\n') if opts[:verbose]

# Now read through the saved lines, saving out the various component parts
full_ref = ''
copyright = ''
passage = ''
version = ''
footnotes = []
number_footnotes = 0 # NB: counting from 0
crossrefs = []
number_crossrefs = 0 # NB: counting from 0
n = 0 # NB: counting from 1
while n < working_line_count
  line = working_lines[n]
  # puts(working_lines[n]).to_s.colorize(:green) if opts[:verbose]
  # Extract full reference
  line.scan(/#{MATCH_REF_RE}/) { |m| full_ref = m.join } if line =~ /#{REF_RE}/
  # Extract version title
  line.scan(/#{MATCH_VERSION_RE}/) { |m| version = m.join } if line =~ /#{VERSION_RE}/
  # Extract passage
  line.scan(/#{MATCH_PASSAGE_RE}/) { |m| passage += m.join } if line =~ /#{PASSAGE_RE}/
  # Extract copyright
  line.scan(/#{MATCH_COPYRIGHT_STRING_RE}/) { |m| copyright = m.join } if line =~ /#{COPYRIGHT_STRING_RE}/
  # Extract footnote
  if line =~ /#{FOOTNOTE_RE}/
    line.scan(/#{MATCH_FOOTNOTE_RE}/) do |m|
      footnotes[number_footnotes] = m.join
      number_footnotes += 1
    end
  end
  # Extract crossref
  if line =~ /#{CROSSREF_RE}/
    line.scan(/#{MATCH_CROSSREF_RE}/) do |m|
      crossrefs[number_crossrefs] = m.join
      number_crossrefs += 1
    end
  end
  n += 1
end
# puts if opts[:verbose]

# Only continue if we have found the passage
if passage.empty?
  puts 'Error: could not find useful data in the page returned from BibleGateway: please check your usage, and if still a problem, please raise an issue on GitHub.'.colorize(:red)
  puts "- full_ref = #{full_ref}"
  puts "- version = #{version}"
  if !opts[:filename].nil?
    puts "- filename = #{opts[:filename]}" 
  else
    puts "- uri = #{uri}"
  end
  puts "- number_footnotes = #{number_footnotes}"
  puts "- number_crossrefs = #{number_crossrefs}"
  exit
end
puts passage.colorize(:yellow) if opts[:verbose]

#---------------------------------------
# Now process the main passage text
#---------------------------------------
# remove UNICODE U+00A0 (NBSP) characters (they are only used in BG for formatting not content) -- this was hard to find!
passage.gsub!(/\u00A0/, '')
# replace HTML &nbsp; and &amp; elements with ASCII equivalents
passage.gsub!(/&nbsp;/, ' ')
passage.gsub!(/&amp;/, '&')
# replace smart quotes with dumb ones
passage.gsub!(/“/, '"')
passage.gsub!(/”/, '"')
passage.gsub!(/‘/, '\'')
passage.gsub!(/’/, '\'')
# replace en dash with markdwon equivalent
passage.gsub!(/—/, '--')

# ignore a particular string in NIV
passage.gsub!(%r{<h3>More on the NIV</h3>}, '')
# ignore <h1> as it doesn't always appear (e.g. Jude)
passage.gsub!(%r{<h1.*?</h1>\s*}, '')
# ignore all <h2>book headings</h2>
passage.gsub!(%r{<h2>.*?</h2>}, '')
# ignore all <hr />
passage.gsub!(%r{<hr />}, '')

# simplify verse/chapters numbers (or remove entirely if that option set)
if opts[:numbering]
  # Now see whether to start chapters and verses as H5 or H6 
  if opts[:newline]
    # Extract the contents of the 'versenum' class (which should just be numbers, but we're not going to be strict)
    passage.gsub!(%r{<sup\sclass="[^"]*?versenum[^"]*?">\s*?(\d+-?\d?)\s*?</sup>}, "\n###### \\1 ")
    # verse number '1' seems to be omitted if start of a new chapter, and the chapter number is given.
    passage.gsub!(%r{<span class="[^"]*?chapternum[^"]*?">\s*?(\d+)\s*?</span>}, "\n##### Chapter \\1\n###### 1 ")
  else
    # Extract the contents of the 'versenum' class (either numbers or number range (for MSG))
    passage.gsub!(%r{<sup\sclass="[^"]*?versenum[^"]*?">\s*?(\d+-?\d?)\s*?</sup>}, "\\1 ")
    # verse number '1' seems to be omitted if start of a new chapter, and the chapter number is given.
    passage.gsub!(%r{<span class="[^"]*?chapternum[^"]*?">\s*?(\d+)\s*?</span>}, "\\1:1 ")
  end
else
  passage.gsub!(%r{<sup class="[^"]*?versenum[^"]*?">.*?</sup>}, '')
  passage.gsub!(%r{<span class="[^"]*?chapternum[^"]*?">.*?</span>}, '')
end

# Modify various things to their markdown equivalent
passage.gsub!(/<p.*?>/, "\n") # needs double quotes otherwise it doesn't turn this into newline
passage.gsub!(%r{</p>}, '')
# If we have editorial headers (which come from <h3> elements) then only output if we want them
if opts[:headers]
  passage.gsub!(/<h3.*?>\s*/, "\n\n## ")
else
  passage.gsub!(/<h3.*?>\s*/, '')
end
passage.gsub!(%r{</h3>}, '')
passage.gsub!(/<b>/, '**')
passage.gsub!(%r{</b>}, '**')
passage.gsub!(%r{<i class=".*?">}, '_') # for LEB etc.
passage.gsub!(/<i>/, '_')
passage.gsub!(%r{</i>}, '_')
passage.gsub!(%r{<br />}, "  \n") # use two trailling spaces to indicate line break but not paragraph break
# Change the small caps around OT 'Lord' and make caps instead
passage.gsub!(%r{<span style="font-variant: small-caps" class="small-caps">Lord</span>}, 'LORD')
# Change the red text for Words of Jesus to be bold instead (if wanted)
passage.gsub!(%r{<span class="woj">(.*?)</span>}, '**\1**') if opts[:boldwords]
# simplify footnotes (or remove if that option set). Complex so do in several stages
if opts[:footnotes]
  passage.gsub!(/<sup data-fn=\'.*?>/, '<sup>')
  passage.gsub!(%r{<sup>\[<a href.*?>(.*?)</a>\]</sup>}, '[^\1]')
else
  passage.gsub!(%r{<sup data-fn.*?<\/sup>}, '')
end
# simplify cross-references (or remove if that option set)
if opts[:crossrefs]
  passage.gsub!(%r{<sup class='crossreference'.*?See cross-reference (\w+).*?</sup>}, '[^\1]')
else
  passage.gsub!(%r{<sup class='crossreference'.*?</sup>}, '')
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
passage = passage.strip # remove leading or trailing whitespace removed

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
# footnote numbering scheme (a..zz). Taken from
# [math - Generate letters to represent number using ruby? - Stack Overflow](https://stackoverflow.com/questions/14632304/generate-letters-to-represent-number-using-ruby)
hf = {}
('a'..'zz').each_with_index { |w, i| hf[i + 1] = w }
# Create an alphabetical hash of numbers (Mod 26) to mimic their
# cross-ref numbering scheme (A..ZZ)
hc = {}
('A'..'ZZ').each_with_index { |w, i| hc[i + 1] = w }

# Finally, prepare the output
output_text = "# #{full_ref} (#{version})\n"
output_text += "#{passage}\n\n"
if number_footnotes.positive? && opts[:footnotes]
  output_text += "### Footnotes\n"
  i = 1
  footnotes.each do |ff|
    output_text += "[^#{hf[i]}]: #{ff}\n"
    i += 1
  end
  output_text += "\n"
end
if number_crossrefs.positive? && opts[:crossrefs]
  output_text += "### Crossrefs\n"
  i = 1
  crossrefs.each do |cc|
    output_text += "[^#{hc[i]}]: #{cc}\n"
    i += 1
  end
  output_text += "\n"
end
output_text += copyright.to_s if opts[:copyright]

# Then write out text
puts
puts output_text
# And also copy it to clipboard
Clipboard.copy(output_text)
