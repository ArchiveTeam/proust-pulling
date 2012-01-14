#!/usr/bin/env ruby

require 'fileutils'
require 'logger'

require File.expand_path('../util', __FILE__)

# Retrieve all non-story Proust content from www.proust.com.

include FileUtils

LOG = Logger.new($stderr)

DEST = File.expand_path("#{Util::DOWNLOAD_TO}/_non_story_content", __FILE__)
warc_file = "#{DEST}/non_story_content"

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
    "--no-remove-listing",
    "--no-timestamping",
    "--page-requisites",
    "--trust-server-names",
    "http://www.proust.com/",
    "http://www.proust.com/about/aboutus",
    "http://www.proust.com/about/help",
    "http://www.proust.com/about/contact",
    "http://www.proust.com/about/press",
    "http://www.proust.com/about/legal/privacy",
    "http://www.proust.com/about/legal/property",
    "http://www.proust.com/about/legal",
    "http://www.proust.com/tour",
    
    "http://www.proust.com/img/press/logos/proust-logo-white.eps",
    "http://www.proust.com/img/press/logos/proust-logo-white.png",
    "http://www.proust.com/img/press/logos/proust-logo-white.gif",
    "http://www.proust.com/img/press/logos/proust-logo-brown.eps",
    "http://www.proust.com/img/press/logos/proust-logo-brown.png",
    "http://www.proust.com/img/press/logos/proust-logo-brown.gif",

    "http://www.proust.com/img/press/PressRelease-PreserveYourMemoriesWithProust.pdf",
    "http://www.proust.com/img/press/PROUST_Print-at-home_release.pdf"
  ].join(' ')

  LOG.debug cmd

  Dir.chdir('fetch') { `#{cmd}` }
end
