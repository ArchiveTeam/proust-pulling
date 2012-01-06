#!/usr/bin/env ruby

require 'fileutils'
require 'mechanize'
require 'logger'
require File.expand_path('../util', __FILE__)

include FileUtils
include Util

LOG = Logger.new($stderr)

# The URLs to image memorabilia are all of the form
#
#   /i/...
#
# Normally, we don't want wget to ascend to an ancestor when retrieving a
# story; however, this is a special case.  To handle this special case, this
# script scrapes all /i/* URLs on a memorabilia page and generates a URL list
# that can be used by wget.

agent = Mechanize.new do |m|
  m.user_agent = 'Mac Safari'
  m.max_history = 1
end

uid = ARGV[0]
url = Util::URL[uid, 'memorabilia']
list_file = list_file_for(uid)

mkdir_p File.dirname(list_file), :verbose => true

LOG.info "Retrieving #{url}"

begin
  page = agent.get(url)
rescue Mechanize::ResponseCodeError => e
  LOG.warn "Code #{e.response_code} returned while fetching #{url}; writing blank file"
  `touch #{list_file}`
  exit 0
end

File.open(list_file, 'w') do |f|
  loop do
    page_num = (page/'#pagePagNumShow').text.strip

    LOG.debug page_num

    (page/'.memBoxGridContainer a.imageFrame').each do |l|
      f.puts "http://www.proust.com#{l.attribute('href').text}"
    end

    has_next = !(page/'a.next').empty?

    break unless has_next

    page = agent.click /^\s*Next/
  end
end
