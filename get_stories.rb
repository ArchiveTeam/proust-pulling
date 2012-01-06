require 'redis'
require 'escape'

r = Redis.new

# All known users.
KNOWN   = 'proust_users'

# Downloads in progress.
WORKING = 'proust_working'

# Downloads completed.
DONE    = 'proust_done'

# Known + working.
PENDING = 'proust_pending'

# Pending - done.
TODO    = 'proust_todo'

r.sunionstore PENDING, KNOWN, WORKING
r.sdiffstore TODO, PENDING, DONE

loop do
  member = r.srandmember(PENDING).tap do |m|
    if m
      r.multi do
        r.srem PENDING, m
        r.sadd WORKING, m
      end
    else
      puts "Nothing left to do."
      exit 0
    end
  end

  puts "Fetching data for #{member}."

  `./get_one_story.rb #{Escape.shell_single_word(member)}`

  if $? == 0
    puts "Retrieved #{member} successfully."

    r.multi do
      r.sadd DONE, member
      r.srem WORKING, member
    end
  else
    puts "Errors encountered retrieving #{member}."
  end
end
