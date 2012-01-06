require 'redis'
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

loop do
  member = r.srandmember(TODO).tap do |m|
    if m
      r.multi do
        r.srem TODO, m
        r.sadd WORKING, m
        r.setex "proust_#{m}_watch", (60 * 60 * 2), 1
      end
    else
      $stderr.puts "Nothing left to do."
      exit 0
    end
  end

  $stderr.puts "Fetching data for #{member}."

  system("./get_one_story.rb #{Escape.shell_single_word(member)}")

  if $? == 0
    $stderr.puts "Retrieved #{member} successfully."

    r.multi do
      r.sadd DONE, member
      r.srem WORKING, member
      r.del "proust_#{m}_watch"
    end
  else
    $stderr.puts "Errors encountered retrieving #{member}."
  end
end
