#!/usr/bin/env ruby

require 'uri'
require 'escape'
require 'fileutils'

include FileUtils

def usage
  puts "#{$0} [user ID]"
end

unless ARGV[0]
  usage
  exit 1
end

uid = URI.encode(ARGV[0])

ACCEPT = %W(
  story/#{uid}
  pi*
  img*
  js*
  css*
).join(',')

E           = lambda { |word| Escape.shell_single_word(word) }
URL         = lambda { |rest| E["http://www.proust.com/story/#{uid}/#{rest}"] }
VERSION     = `git log -n1 --oneline #{$0} | awk '{print $1}'`.chomp
WGET_WARC   = File.expand_path('../wget-warc', __FILE__)
USER_AGENT  = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.874.54 Safari/535.2'
DOWNLOAD_TO = File.expand_path('../data', __FILE__)

warc_file = "#{DOWNLOAD_TO}/#{uid[0..0]}/#{uid[0..1]}/#{uid[0..2]}/#{uid}/#{uid}"
mkdir_p File.dirname(warc_file)

cmd = [
  WGET_WARC,
  "-U " + E[USER_AGENT],
  "-o " + E["#{warc_file}.log"],
  "-e robots=off",
  "--warc-file=" + E[warc_file],
  "--warc-max-size=inf",
  "--warc-cdx",
  "--warc-header='operator: Archive Team'",
  "--warc-header='proust-dld-script-version: #{VERSION}'",
  "-nv",
  "-np",
  "-r",
  "-l inf",
  "--no-remove-listing",
  "--no-timestamping",
  "--page-requisites",
  "--trust-server-names",
  "--force-directories",
  URL[''],
  URL['all'],
  URL['map'],
  URL['timeline'],
  URL['memorabilia'],
  URL['tagged']
]

puts cmd.join(' ')
