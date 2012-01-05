#!/usr/bin/env ruby

require 'uri'
require 'fileutils'

include FileUtils

VERSION     = `git log -n1 --oneline #{$0} | awk '{print $1}'`.chomp
WGET_WARC   = './wget-warc'
USER_AGENT  = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.874.54 Safari/535.2'
DOWNLOAD_TO = File.expand_path('../data', __FILE__)

EXCLUDED_DIRECTORIES = %w(
  questions
  world-events
  people
  tour
  about
).join(',')

def usage
  puts "#{$0} [user ID]"
end

unless ARGV[0]
  usage
  exit 1
end

uid = URI.encode(ARGV[0])
warc_file = "#{DOWNLOAD_TO}/#{uid[0..0]}/#{uid[0..1]}/#{uid[0..2]}/#{uid}"
mkdir_p File.dirname(warc_file)

cmd = [
  WGET_WARC,
  "-U #{USER_AGENT}",
  "--warc-file #{warc_file}",
  "--warc-max-size=inf",
  "--warc-cdx",
  "--warc-header='operator: Archive Team'",
  "--warc-header='proust-dld-script-version: #{VERSION}'",
  "-nv",
  "-r",
  "-l inf",
  "--no-remove-listing",
  "--no-timestamping",
  "--page-requisites",
  "--trust-server-names",
  "--exclude-directories=#{EXCLUDED_DIRECTORIES}",
  "http://www.proust.com/story/#{uid}"
]

puts cmd.join(' ')
