require 'rubygems'
require 'bundler/setup'

require 'scraperwiki'
require 'twitter_list'

class TwitterListScraper
  def initialize(user:, list:)
    @user = user
    @list = list
  end

  def to_a
    abort "Need to set ENV['MORPH_TWITTER_TOKENS']" unless ENV.key? 'MORPH_TWITTER_TOKENS'
    @twitter_list ||= TwitterList::Scraper.new(twitter_tokens: ENV['MORPH_TWITTER_TOKENS']).people(user, list)
  end

  private

  attr_reader :user, :list
end
