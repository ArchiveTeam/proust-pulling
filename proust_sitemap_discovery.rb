#!/usr/bin/env ruby

require 'mechanize'
require 'nokogiri'
require 'redis'
require 'stringio'
require 'zlib'

require File.expand_path('../redis_config', __FILE__)

# Proust has a sitemap at http://www.proust.com/sitemap.xml.gz.  This lists
# some public profiles, which we can use to augment our user index.

agent = Mechanize.new

data = agent.get('http://www.proust.com/sitemap.xml.gz')
zstream = Zlib::Inflate.new
io = StringIO.new(data.body)

gz = Zlib::GzipReader.new(io)
xml = gz.read
doc = Nokogiri.XML(xml)
gz.close

users = (doc/'url > loc').map { |e| e.text }.map { |t| t =~ %r{/story/([^/]+)}; $1 }.compact.uniq

r = Redis.new

users.each { |user| r.sadd KNOWN, user }
