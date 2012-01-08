require 'escape'

module Util
  E           = lambda { |word| Escape.shell_single_word(word) }
  URL         = lambda { |uid, rest| "http://www.proust.com/story/#{uid}/#{rest}" }
  VERSION     = `git log -n1 --oneline #{$0} | awk '{print $1}'`.chomp
  WGET_WARC   = File.expand_path('../wget-warc', __FILE__)
  USER_AGENT  = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.874.54 Safari/535.2'
  DOWNLOAD_TO = File.expand_path('../data', __FILE__)

  def warc_path_for(uid)
    "#{DOWNLOAD_TO}/#{uid[0..0]}/#{uid[0..1]}/#{uid[0..2]}/#{uid}/#{uid}"
  end

  def list_file_for(uid)
    "#{warc_path_for(uid)}.memorabilia"
  end

  def log_for(uid)
    "#{warc_path_for(uid)}.log"
  end

  def wget_command_for(uid)
    warc_file = warc_path_for(uid)
    list_file = list_file_for(uid)
    log_file = log_for(uid)

    [
      WGET_WARC,
      "-U " + E[USER_AGENT],
      "-o " + E[log_file],
      "-e robots=off",
      "--warc-file=" + E[warc_file],
      "--warc-max-size=inf",
      "--warc-cdx",
      "--warc-header='operator: Archive Team'",
      "--warc-header='proust-dld-script-version: #{VERSION}'",
      "-nv",
      "-np",
      "-nd",
      "-r",
      "-l inf",
      "--no-remove-listing",
      "--no-timestamping",
      "--page-requisites",
      "--trust-server-names",

      # Memorabilia image URLs
      "-i " + E[list_file],

      # Root URLs of stories
      E[URL[uid, '']],
      E[URL[uid, 'all']],
      E[URL[uid, 'map']],
      E[URL[uid, 'timeline']],
      E[URL[uid, 'memorabilia']],
      E[URL[uid, 'tagged']],

      # External Javascripts
      "http://www.google.com/jsapi",
      "http://platform.twitter.com/widgets.js",
      "http://use.typekit.com/bju4bye.js",
      "http://edge.quantserve.com/quant.js",
      "https://apis.google.com/js/plusone.js",
      "http://www.google-analytics.com/ga.js"
    ].join(' ')
  end
end
