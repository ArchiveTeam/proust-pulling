#!/usr/bin/env ruby

require File.expand_path('../util', __FILE__)
require 'fileutils'
require 'logger'

LOG = Logger.new($stderr)

include FileUtils
include Util

def usage
  $stderr.puts "#{$0} [user ID]"
end

def only_404s?(log_file)
  errors = `grep ERROR #{log_file}`.split("\n")
  LOG.debug "Examining #{errors.length} errors."

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
LOG.debug cmd

Dir.chdir(fetch_target) { `#{cmd}` }

if $?.success?
  rm_rf fetch_target, :verbose => true
  exit 0
else
  status = $?.exitstatus

  # Exit status 8: "Server issued an error response"
  if status == 8
    LOG.warn "wget says the server issued errors; checking errors."
    # Scan the log for errors.  If all we see are 404s, then it's probably ok.
    if only_404s?(log_for(user))
      LOG.info "All error responses are 404s; exiting normally."
      rm_rf fetch_target, :verbose => true
      exit 0
    else
      LOG.error "Non-404 error responses detected; exiting with status #{status}."
      exit status
    end
  end
end
