# Proust homepage URLs have the form
#
#     http://www.proust.com/story/foo
#
# not
#     
#     http://www.proust.com/story/foo/
#
# even though the Proust webapp returns the same response for either request.
# The latter was used in the main grab because I couldn't figure out a way for
# the former to work with all the other options.  So here's a script to remedy # just that problem.

require 'fileutils'
require 'logger'

require File.expand_path('../util', __FILE__)

include FileUtils
include Util

LOG = Logger.new($stderr)

def only_404s?(log_file)
  errors = `grep ERROR #{log_file}`.split("\n")
  LOG.debug "Examining #{errors.length} errors."

  errors.all? { |e| e =~ /ERROR 404/ }
end

# For each retrieved user:
Dir['data/**/*.warc.gz'].reject { |w| w =~ /.+_rootless_home\.warc\.gz$/ }.map do |f|

  # ...get the directory and the username...
  f =~ %r{([^/]+)\.warc\.gz$}
  [File.expand_path(File.dirname(f)), $1]
end.each do |dir, user|
  Dir.chdir(dir) do
    # ...and fetch http://www.proust.com/story/#{user}.
    mkdir_p 'fetch'

    warc_file = warc_path_for(user) + "_rootless_home"
    cdx_file = warc_path_for(user) + ".cdx"
    log_file = "#{dir}/#{user}_rootless_home.log"

    if File.exists?(warc_file + ".warc.gz")
      LOG.info "Already retrieved http://www.proust.com/story/#{user}."
      next
    end

    Dir.chdir('fetch') do
      cmd = [
        Util::WGET_WARC,
        "-U " + Util::E[Util::USER_AGENT],
        "-o " + Util::E[log_file],
        "-e robots=off",
        "--warc-file=" + E[warc_file],
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
        E["http://www.proust.com/story/#{user}"],

        # External Javascripts
        "http://www.google.com/jsapi",
        "http://platform.twitter.com/widgets.js",
        "http://use.typekit.com/bju4bye.js",
        "http://edge.quantserve.com/quant.js",
        "https://apis.google.com/js/plusone.js",
        "http://www.google-analytics.com/ga.js"
      ].join(' ')

      LOG.debug cmd
      `#{cmd}`
    end

    if $?.success?
      rm_rf 'fetch', :verbose => true
      exit 0
    else
      status = $?.exitstatus

      # Exit status 8: "Server issued an error response"
      if status == 8
        LOG.warn "wget says the server issued errors; checking errors."
        # Scan the log for errors.  If all we see are 404s, then it's probably ok.
        if only_404s?(log_file)
          LOG.info "All error responses are 404s; marking as ok."
          rm_rf 'fetch', :verbose => true
        else
          LOG.error "Non-404 error responses detected; keeping fetched data around for inspection."
        end
      end
    end
  end
end
