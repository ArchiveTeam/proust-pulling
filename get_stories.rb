#!/usr/bin/env ruby

require 'escape'
require 'logger'
require 'mechanize'
require 'redis'

require File.expand_path('../redis_config', __FILE__)
require File.expand_path('../util', __FILE__)

r = Redis.new

r.sdiffstore TODO, KNOWN, DONE

LOG = Logger.new($stderr)

agent = Mechanize.new do |m|
  m.max_history = 0
  m.user_agent = 'Mac Safari'
end

def finish(member, r)
  r.multi do
    r.sadd DONE, member
    r.srem WORKING, member
    r.del "proust_#{member}_watch"
  end
end

loop do
  member = r.srandmember(TODO).tap do |m|
    if m
      r.multi do
        r.srem TODO, m
        r.sadd WORKING, m
        r.setex "proust_#{m}_watch", (60 * 60 * 2), 1
      end
    else
      LOG.info "Nothing left to do."
      exit 0
    end
  end


  LOG.info "Checking if #{member} has marked their story as private."

  # Check if the member's story is private.  If it is, file it as private and
  # move on to another member.
  page = agent.get(Util::URL[member, ''])
  marker = (page/'#psbLeftHalf').text.strip

  LOG.debug marker

  if marker =~ /this is .* private story/i
    LOG.info "#{member} is marked private; deferring retrieval."
    r.sadd PRIVATE, member
    finish member, r
  else
    LOG.info "#{member} is marked public."
    LOG.info "Fetching data for #{member}."

    system("./get_one_story.rb #{Escape.shell_single_word(member)}")

    if $? == 0
      LOG.info "Retrieved #{member} successfully."

      finish member, r
    else
      LOG.error "Errors encountered retrieving #{member}."
    end
  end
end
