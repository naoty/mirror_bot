module MirrorBot
  class Tweet < Sequel::Model
    # Heroku Postgresql Free plan is limited up to 10000 rows.
    ROW_LIMIT = 10000

    MINUTES_PER_DAY = 24 * 60
    SAMPLE_MINUTE_RANGE = 30

    dataset_module do
      def sample_by_minute(minute)
        min_minute = minute - SAMPLE_MINUTE_RANGE
        max_minute = minute + SAMPLE_MINUTE_RANGE
        if min_minute < 0
          dataset = where(minute: (MINUTES_PER_DAY + min_minute)...MINUTES_PER_DAY).or(minute: 0..max_minute)
        elsif max_minute >= MINUTES_PER_DAY
          dataset = where(minute: min_minute...MINUTES_PER_DAY).or(minute: 0..(max_minute - MINUTES_PER_DAY))
        else
          dataset = where(minute: min_minute..max_minute)
        end
        dataset
      end
    end

    def before_create
      ensure_timestamp
      ensure_row_limit
      super
    end

    private

    def ensure_timestamp
      self.created_at ||= Time.now
    end

    def ensure_row_limit
      total_count = Tweet.count
      if total_count >= ROW_LIMIT - 1
        exceeded_count = total_count - ROW_LIMIT
        exceeded_tweets = Tweet.order(:id).reverse.limit(exceeded_count)
        exceeded_tweets.destroy
      end
    end
  end
end