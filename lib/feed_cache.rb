require 'digest/sha1'
require 'feedzirra'

class FeedCache
  include Simpleton
  
  # Return the contents of a feed, either from the cached copy or from a new request.
  # Options:
  # :expires_in For MemCacheStore, if in utilized.
  # :stale_after (in seconds).  The amount of time after the last post in a feed to break the cache and refresh the feed.
  # i.e.: get(url, :stale_after => 1.day) will cache the results until one day after the last post in that feed.
  def get(url, *args)
    expires_in = parse_expiration(args.delete(:expires_in))
    stale_after = parse_expiration(args.delete(:stale_after))
    feed_cache_key = cache_key(url)

    # Enable media content from RSS feeds.
    Feedzirra::Feed.add_common_feed_entry_element("media:content", :value => "url", :as => :media_content_url)

    feed = Rails.cache.fetch(feed_cache_key, :expires_in => expires_in) do
      begin
        Feedzirra::Feed.fetch_and_parse(url, :on_failure => lambda{ raise })
      rescue
        nil
      end
    end

    # Expire the feed if the last modified date is greater than our stale time of if the results were bad
    if feed.nil? || (stale_after && ((last_modified(feed) + stale_after) < Time.now))
      Rails.cache.delete(feed_cache_key)
    end

    feed || 0
  end
  
  private
    
  def cache_key(url)
    Digest::SHA1.hexdigest(url)
  end

  # We can't use the built-in last_modified() method in Feedzirra, since it tries to modify
  # itself (by writing an instance variable), but anything coming out of the cache is frozen.  
  # So we manually look through our entries for the most-recent post date.
  def last_modified(feed)
    return nil unless feed.respond_to?(:entries)
    last_modified = feed.entries.map {|e| e.published}.compact.sort.last
  end

  def parse_expiration(expiration = '')
    if expiration =~ /([0-9]+)\s(second(s)?|minute(s)?|hour(s)?|day(s)?|week(s)?|year(s)?)/
      components = expiration.split(' ')
      components.first.to_i.send(components.second.to_sym)
    end
  end

end