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
        tweets = Tweet.where(reply_user_id: nil).sample_by_minute(minute)
        tweet = tweets.to_a.sample
        @rest_client.update(tweet.text)
      end
    end

    def start_streaming_client
      bot = @rest_client.user(skip_status: true)
      begin
        @streaming_client.user do |object|
          case object
          when Twitter::Tweet
            case @classifier.classify(object)
            when :favorite
              @rest_client.favorite(object)
            end
            reply_to(object) if object.in_reply_to_user_id == bot.id
          end
        end
      rescue EOFError
        puts "Bot stream has been disconnected. Retry to connect."
        sleep 10
        retry
      end
    end

    def reply_to(tweet)
      replies = Tweet.where(reply_user_id: tweet.user.id)
      reply = replies.to_a.sample
      @rest_client.update(reply.text, in_reply_to_status: tweet)
    end
  end
end