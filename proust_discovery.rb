# encoding: UTF-8

require 'mechanize'
require 'redis'

r = Redis.new

agent = Mechanize.new do |m|
  m.user_agent_alias = 'Mac Safari'
  m.max_history = 1
end

page = agent.get 'http://www.proust.com/people'

loop do
  has_next = !(page/'a.next').empty?

  break unless has_next

  (page/'.SEOPeopleOnProustDetails a.standardBlueLink').each do |l|
    r.sadd 'proust_stories', l.attribute('href').text
  end

  count = r.scard 'proust_stories'

  puts "Proust index page: #{page.uri}, discovered #{count} stories"

  page = agent.click /Next/

  sleep rand(5)
end

