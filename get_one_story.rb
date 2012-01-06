#!/usr/bin/env ruby

require File.expand_path('../util', __FILE__)
require 'fileutils'

include FileUtils
include Util

def usage
  $stderr.puts "#{$0} [user ID]"
end

def only_404s?(log_file)
  errors = `grep ERROR #{log_file}`.split("\n")

  errors.all? { |e| e =~ /ERROR 404/ }
end

unless ARGV[0]
  usage
  exit 1
end

user = ARGV[0]
warc_file = warc_path_for(user)
mkdir_p File.dirname(warc_file), :verbose => true

system("./get_memorabilia_urls.rb #{user}")

fetch_target = File.join(File.dirname(warc_file), 'fetch')
rm_rf fetch_target, :verbose => true
mkdir_p fetch_target, :verbose => true

cmd = wget_command_for(user)
$stderr.puts cmd

Dir.chdir(fetch_target) { `#{cmd}` }

if $?.success?
  exit 0
else
  status = $?.exitstatus

  # Exit status 8: "Server issued an error response"
  if status == 8
    # Scan the log for errors.  If all we see are 404s, then it's probably ok.
    if only_404s?(log_for(user))
      $stderr.puts "wget detected 404s; exiting normally."
      exit 0
    else
      $stderr.puts "wget exited with status #{status}."
      exit status
    end
  end
end
