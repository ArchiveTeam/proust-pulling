require 'mechanize'
require 'redis'

r = Redis.new

agent = Mechanize.new do |m|
  m.user_agent = 'Mac Safari'
  m.max_history = 5
end

page = agent.get 'http://www.google.com/search?q=site:http://www.proust.com/story'

loop do
  has_next = (page/'td').detect { |x| x.inner_html =~ /Next/ }

  break unless has_next

  stories = page.links_with(:href => %r{^http://www\.proust\.com/story}).map { |l| l.href }
  stories.each { |s| r.sadd 'proust_stories', s }

  page = agent.click 'Next'
  count = r.scard 'proust_stories'

  puts "Search result page: #{page.uri}, discovered #{count} stories"

  sleep rand(5)
end
