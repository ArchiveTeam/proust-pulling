require 'redis'
require 'escape'

r = Redis.new

r.sdiffstore 'proust_todo', 'proust_users', 'proust_done'

r.smembers('proust_todo').each do |member|
  puts "Retrieving #{member}."
  cmd = `./gen_story_cmd.rb #{Escape.shell_single_word(member)}`

  puts cmd
  `#{cmd}`

  if $? == 0
    puts "Retrieved #{member} successfully."
    r.sadd 'proust_done', member
  else
    puts "Errors encountered retrieving #{member}."
  end
end
