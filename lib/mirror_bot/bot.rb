require "twitter"

module MirrorBot
  class Bot
    def initialize
      @streaming_client = Twitter::Streaming::Client.new do |config|
        config.consumer_key = ENV["BOT_CONSUMER_KEY"]
        config.consumer_secret = ENV["BOT_CONSUMER_SECRET"]
        config.access_token = ENV["BOT_ACCESS_TOKEN"]
        config.access_token_secret = ENV["BOT_ACCESS_TOKEN_SECRET"]
      end
      @rest_client = Twitter::REST::Client.new do |config|
        config.consumer_key = ENV["BOT_CONSUMER_KEY"]
        config.consumer_secret = ENV["BOT_CONSUMER_SECRET"]
        config.access_token = ENV["BOT_ACCESS_TOKEN"]
        config.access_token_secret = ENV["BOT_ACCESS_TOKEN_SECRET"]
      end
      @scheduler = Scheduler.new
      @classifier = Classifier.new
    end

    def start
      threads = []
      threads << Thread.new { start_scheduler }
      threads << Thread.new { start_streaming_client }
      threads.each(&:join)
    end

    private

    def start_scheduler
      @scheduler.start do
        now = Time.now
        minute = now.hour * 60 + now.min
        tweet = Tweet.sample_by_minute(min: minute - 30 * 60, max: minute + 30 * 60)
        @rest_client.update(tweet.text)
      end
    end

    def start_streaming_client
      @streaming_client.user do |object|
        case object
        when Twitter::Tweet
          case @classifier.classify(object)
          when :favorite
            @rest_client.favorite(object)
          end
        end
      end
    end
  end
end