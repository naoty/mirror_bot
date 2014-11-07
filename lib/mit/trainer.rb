require "twitter"

module MiT
  class Trainer
    def initialize
      @client = Twitter::REST::Client.new do |config|
        config.consumer_key = ENV["HUMAN_CONSUMER_KEY"]
        config.consumer_secret = ENV["HUMAN_CONSUMER_SECRET"]
        config.access_token = ENV["HUMAN_ACCESS_TOKEN"]
        config.access_token_secret = ENV["HUMAN_ACCESS_TOKEN_SECRET"]
      end
    end

    def train_scheduler
      # NOTE: User timeline API returns only up to 3,200 tweets
      options = { count: 200 }
      16.times do
        tweets = @client.user_timeline(options)
        tweets.each do |tweet|
          train_tweet(tweet)
        end
        options[:max_id] = tweets.last.id - 1
      end
    end

    def train_tweet(tweet)
      minute = tweet.created_at.hour * 60 + tweet.created_at.min
      Tweet.create(tweet_id: tweet.id, text: tweet.text, minute: minute)
    end
  end
end