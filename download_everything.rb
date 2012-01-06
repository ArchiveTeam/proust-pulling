#!/usr/bin/env ruby

require 'girl_friday'
require 'redis'
require 'logger'
require 'fileutils'

require File.expand_path('../redis_config', __FILE__)
require File.expand_path('../util', __FILE__)

# This is an alternative download strategy that starts at http://www.proust.com/
# and tries to download everything linked from that in one go, using harvested
# story profiles and memorabilia URLs as guides.
DEST = File.expand_path("#{Util::DOWNLOAD_TO}/everything", __FILE__)

LOG = Logger.new($stderr)

warc_file = "#{DEST}/proust"

include FileUtils

r = Redis.new

known = r.smembers(KNOWN)

mkdir_p DEST
mkdir_p "#{DEST}/fetch"

# Build memorabilia URLs for each member.
batch = GirlFriday::Batch.new(known, :size => 2) do |user|
  LOG.info "Retrieving memorabilia for #{user}"
  system("./get_memorabilia_urls.rb #{user}")
end

batch.results

Dir.chdir(DEST) do
  # Coalesce all memorabilia URLs into one file.
  `find .. -iname *.memorabilia | xargs -I '{}' cat '{}' >> all_memorabilia`

  # Build a story URL for each member.
  File.open('all_stories', 'w') do |f|
    known.each { |user| f.puts Util::URL[user, ''] }
  end

  # Run wget.
  cmd = [
    Util::WGET_WARC,
    "-U " + Util::E[Util::USER_AGENT],
    "-o " + Util::E[warc_file + '.log'],
    "-e robots=off",
    "--warc-file=" + Util::E[warc_file],
    "--warc-max-size=inf",
    "--warc-cdx",
    "--warc-header='operator: Archive Team'",
    "--warc-header='proust-dld-script-version: #{Util::VERSION}'",
    "-nv",
    "-np",
    "-nd",
    "-r",
    "-l inf",
    "--no-remove-listing",
    "--no-timestamping",
    "--page-requisites",
    "--trust-server-names",
    
    # Memorabilia URLs
    "-i all_memorabilia",
    "-i all_stories",
    "http://www.proust.com"
  ].join(' ')

  LOG.debug cmd
  
  Dir.chdir('fetch') { `#{cmd}` }
end
