#!/usr/bin/env ruby

require 'fileutils'
require 'logger'

require File.expand_path('../util', __FILE__)

# Proust's blog has value, too.

include FileUtils

LOG = Logger.new($stderr)

DEST = File.expand_path("#{Util::DOWNLOAD_TO}/_blog", __FILE__)
warc_file = "#{DEST}/blog"

mkdir_p DEST
mkdir_p "#{DEST}/fetch"

Dir.chdir(DEST) do
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
    "http://blog.proust.com"
  ].join(' ')

  LOG.debug cmd

  Dir.chdir('fetch') { `#{cmd}` }
end
