require File.dirname(__FILE__) + '/../spec_helper'

describe FeedCache do
  before :each do
    @cache = FeedCache.instance
  end

  it "should be a Simpleton" do
    FeedCache.included_modules.should include(Simpleton)
  end

  it "should not cache the feed if there is an error in fetching" do
    @cache.get('http://seancribbs.com/this-does-not-exist')
    key = @cache.send(:cache_key, 'http://seancribbs.com/this-does-not-exist')
    Rails.cache.exist?(key).should be_false
  end

  it "should save the feed to the Rails cache when fetching" do
    @cache.get('http://seancribbs.com/atom.xml')
    key = @cache.send(:cache_key, 'http://seancribbs.com/atom.xml')
    Rails.cache.exist?(key).should be_true
  end

  it "should return the cached feed" do
    @old = @cache.get('http://seancribbs.com/atom.xml')
    @old.etag.should == @cache.get('http://seancribbs.com/atom.xml').etag
  end

  it "should not expire the cache if the current time is not greater than the stale_after parameter plus the last_modified date" do
    @cache.stub!(:last_modified).with(anything()).and_return(2.days.ago)
    @cache.get('http://seancribbs.com/atom.xml', :stale_after => 1.week)
    key = @cache.send(:cache_key, 'http://seancribbs.com/atom.xml')
    Rails.cache.exist?(key).should be_true
  end

  it "should expire the cache if the current time is greater than the stale_after parameter plus the last_modified date" do
    @cache.stub!(:last_modified).with(anything()).and_return(2.days.ago)
    @cache.get('http://seancribbs.com/atom.xml', :stale_after => 1.day)
    key = @cache.send(:cache_key, 'http://seancribbs.com/atom.xml')
    Rails.cache.exist?(key).should be_true
  end

end