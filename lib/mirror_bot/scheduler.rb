module MirrorBot
  class Scheduler
    SCHEDULE_UPDATE_INTERVAL = 24 * 60 * 60
    SCHEDULE_INTERVAL = 1 * 60
    TWEET_COUNT_RANGE_PER_DAY = (10..20)

    def initialize
      @threads = []
      @scheduled_minutes = []
    end

    def start(&block)
      start_schedule_update
      start_schedule(&block)
      @threads.each(&:join)
    end

    private

    def start_schedule_update
      @threads << Thread.new do
        loop do
          determine_schedule!
          sleep(SCHEDULE_UPDATE_INTERVAL)
        end
      end
    end

    def start_schedule(&block)
      @threads << Thread.new do
        loop do
          block.call if on_time?
          sleep(SCHEDULE_INTERVAL)
        end
      end
    end

    def determine_schedule!
      @scheduled_minutes.clear

      accumulated_probabilities = calculate_accumulated_probabilities
      return if accumulated_probabilities.empty?

      tweet_count_per_day = rand(TWEET_COUNT_RANGE_PER_DAY)
      tweet_count_per_day.times do
        r = rand
        minute = accumulated_probabilities.index { |p| p > r }
        @scheduled_minutes << minute
        accumulated_probabilities.delete_at(minute)
      end
    end

    def calculate_accumulated_probabilities
      accumulated_probabilities = []

      tweets = Tweet.all
      total_count = tweets.count
      return accumulated_probabilities if total_count.zero?

      indexed_tweets = tweets.group_by(&:minute)
      accumulated_probability = 0.0

      # minutes per day
      1439.times do |minute|
        tweets = indexed_tweets[minute]
        tweet_count = tweets.nil? ? 0 : tweets.count
        probability = total_count.zero? ? 0.0 : tweet_count.to_f / total_count
        accumulated_probability += probability
        accumulated_probabilities << accumulated_probability
      end

      accumulated_probabilities
    end

    def on_time?
      now = Time.now
      minute = now.hour * 60 + now.min
      @scheduled_minutes.include?(minute)
    end
  end
end