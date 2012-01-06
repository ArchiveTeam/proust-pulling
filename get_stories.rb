#!/usr/bin/env ruby

require 'redis'
require 'logger'
require 'escape'

r = Redis.new

# All known users.
KNOWN   = 'proust_users'

# Downloads in progress.
WORKING = 'proust_working'

# Downloads completed.
DONE    = 'proust_done'

# Pending - done.
TODO    = 'proust_todo'

r.sdiffstore TODO, KNOWN, DONE

LOG = Logger.new($stderr)

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

  LOG.info "Fetching data for #{member}."

  system("./get_one_story.rb #{Escape.shell_single_word(member)}")

  if $? == 0
    LOG.info "Retrieved #{member} successfully."

    r.multi do
      r.sadd DONE, member
      r.srem WORKING, member
      r.del "proust_#{member}_watch"
    end
  else
    LOG.error "Errors encountered retrieving #{member}."
  end
end
