#!/usr/bin/ruby

require 'scraperwiki'
require 'nokogiri'
require 'open-uri'
require './twitter_scraper'

require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def twitter_list(url)
  noko = noko_for(url)
  table = noko.xpath('//table[.//th[.="username"]]')
  table.xpath('.//tr[td]').map do |tr|
    td = tr.css('td')
    data = {
      id: td[0].css('a/@href').text.split('/').last,
      name: td[1].text.tidy,
      twitter: td[0].text.tidy,
      area: td[5].text,
      source: URI.join(url, td[0].css('a/@href').text).to_s,
    }
  end
end

def facebook_list(url)
  noko = noko_for(url)
  table = noko.xpath('//table[.//th[.="name"]]')
  table.xpath('.//tr[td]').map do |tr|
    td = tr.css('td')
    data = {
      id: td[1].css('a/@href').text.split('/').last,
      name: td[1].text.tidy,
      facebook: td[7].css('a[href*="facebook"]/@href').text
    }
  end
end

def youtube_list(url)
  noko = noko_for(url)
  table = noko.xpath('//table[.//th[.="name"]]')
  table.xpath('.//tr[td]').map do |tr|
    td = tr.css('td')
    data = {
      id: td[1].css('a/@href').text.split('/').last,
      name: td[1].text.tidy,
      youtube: td[-1].css('a/@href').text
    }
  end
end

twitter = twitter_list('http://politwitter.ca/page/canadian-politics-twitters/mp/house') +
          TwitterListScraper.new(user: 'politwoops', list: 'ca').to_a +
          TwitterListScraper.new(user: 'cka_politwit', list: 'federal-mps').to_a

facebook = facebook_list('http://politwitter.ca/directory/facebook/mp/house')
youtube = youtube_list('http://politwitter.ca/directory/youtube/mp/house')

data = twitter.group_by { |h| h[:id] }

facebook.each do |h|
  if data.key? h[:id]
    data[h[:id]].first.merge! h
  else 
    data[h[:id]] = [h]
  end
end

youtube.each do |h|
  if data.key? h[:id]
    data[h[:id]].first.merge! h
  else 
    data[h[:id]] = [h]
  end
end

ScraperWiki.save_sqlite([:id], data.values.flatten)
