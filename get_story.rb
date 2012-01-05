#!/usr/bin/env ruby

require 'uri'
require 'fileutils'

include FileUtils

VERSION     = `git log -n1 --oneline #{$0} | awk '{print $1}'`.chomp
WGET_WARC   = File.expand_path('../wget-warc', __FILE__)
USER_AGENT  = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.874.54 Safari/535.2'
DOWNLOAD_TO = File.expand_path('../data', __FILE__)
def usage
  puts "#{$0} [user ID]"
end

unless ARGV[0]
  usage
  exit 1
end

uid = URI.encode(ARGV[0])
warc_file = "#{DOWNLOAD_TO}/#{uid[0..0]}/#{uid[0..1]}/#{uid[0..2]}/#{uid}/#{uid}"
mkdir_p File.dirname(warc_file)

BASE_URL = lambda { |rest| "http://www.proust.com/story/#{uid}/#{rest}" }
ACCEPT = %W(
  story/#{uid}
  pi*
  img*
  js*
  css*
).join(',')

cmd = [
  WGET_WARC,
  "-U '#{USER_AGENT}'",
  "-o #{warc_file}.log",
  "-e 'robots=off'",
  "--warc-file #{warc_file}",
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
  BASE_URL[''],
  BASE_URL['all'],
  BASE_URL['map'],
  BASE_URL['timeline'],
  BASE_URL['memorabilia'],
  BASE_URL['tagged']
]

puts cmd.join(' ')
