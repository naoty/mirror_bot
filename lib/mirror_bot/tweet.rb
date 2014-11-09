module MirrorBot
  class Tweet < Sequel::Model
    # Heroku Postgresql Free plan is limited up to 10000 rows.
    ROW_LIMIT = 10000

    def before_create
      total_count = Tweet.count
      if total_count >= ROW_LIMIT - 1
        exceeded_count = total_count - ROW_LIMIT
        exceeded_tweets = Tweet.order(:id).reverse.limit(exceeded_count)
        exceeded_tweets.destroy
      end
      super
    end

    def self.sample_by_minute(min: 0, max: 24 * 60)
      self.where(minute: min..max).to_a.sample
    end
  end
end