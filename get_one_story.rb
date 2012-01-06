#!/usr/bin/env ruby

require File.expand_path('../util', __FILE__)
require 'fileutils'

include FileUtils
include Util

def usage
  puts "#{$0} [user ID]"
end

unless ARGV[0]
  usage
  exit 1
end

user = ARGV[0]
warc_file = warc_path_for(user)
mkdir_p File.dirname(warc_file), :verbose => true

fetch_target = File.join(File.dirname(warc_file), 'fetch')
rm_rf fetch_target, :verbose => true
mkdir_p fetch_target, :verbose => true

cmd = wget_command_for(user)
puts cmd

Dir.chdir(fetch_target) { `#{cmd}` }

if $?.success?
  exit 0
else
  exit $?.exitstatus
end
