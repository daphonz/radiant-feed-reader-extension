class FeedReaderExtension < Radiant::Extension
  version "0.6"
  description "This extension uses Paul Dix's Feedzirra to render newsfeeds.  Inspired by scidept's original rss-reader extension."
  url "http://http://github.com/daphonz/radiant-feed-reader-extension"

  def activate
    FeedCache
    Page.class_eval { include FeedReaderTags }
  end
end