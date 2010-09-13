require 'digest/sha1'
require 'feedzirra'

class FeedCache
  include Simpleton
  
  attr_accessor :cache_dir
  
  def get(url, *args)
    expires_in = parse_expiration(args.delete(:expires_in))
    stale_after = parse_expiration(args.delete(:stale_after))
    feed_cache_key = cache_key(url)
    
    feed = Rails.cache.fetch(feed_cache_key, :expires_in => expires_in) do
      begin
        # Enable media content from RSS feeds.
        Feedzirra::Feed.add_common_feed_entry_element("media:content", :value => "url", :as => :media_content_url)
        Feedzirra::Feed.fetch_and_parse(url, :on_failure => lambda{ raise })
      rescue
        nil
      end
    end
    
    # Expire the feed if the last modified date is greater than our stale time of if the results were bad
    if feed.nil? || (stale_after && feed && (feed.last_modified + stale_after) < Time.now)
      Rails.cache.delete(feed_cache_key)
    end
    
    feed || 0
  end
  
  private
    
  def cache_key(url)
    Digest::SHA1.hexdigest(url)
  end
  
  def parse_expiration(expiration = '')
    if expiration =~ /([0-9]+)\s(second(s)?|minute(s)?|hour(s)?|day(s)?|week(s)?|year(s)?)/
      components = expiration.split(' ')
      components.first.to_i.send(components.second.to_sym)
    end
  end

end