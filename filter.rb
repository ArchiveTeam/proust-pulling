require 'redis'

r = Redis.new

r.smembers('proust_stories').each do |url|
  url =~ %r{/story/([^/]+)}
  r.sadd('proust_users', $1)
end
