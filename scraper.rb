#!/usr/bin/ruby

require 'scraperwiki'
require 'nokogiri'
require 'open-uri'

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

def scrape_list(url)
  noko = noko_for(url)
  table = noko.xpath('//table[.//th[.="username"]]')
  table.xpath('.//tr[td]').each do |tr|
    td = tr.css('td')
    data = {
      name: td[1].text.tidy,
      twitter: td[0].text.tidy,
      area: td[5].text,
      source: URI.join(url, td[0].css('a/@href').text).to_s,
    }
    ScraperWiki.save_sqlite([:twitter], data)
  end
end

scrape_list('http://politwitter.ca/page/canadian-politics-twitters/mp/house')
