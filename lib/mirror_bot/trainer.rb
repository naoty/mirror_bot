require "redis"
require "twitter"

module MirrorBot
  class Trainer
    def initialize
      @client = Twitter::REST::Client.new do |config|
        config.consumer_key = ENV["HUMAN_CONSUMER_KEY"]
        config.consumer_secret = ENV["HUMAN_CONSUMER_SECRET"]
        config.access_token = ENV["HUMAN_ACCESS_TOKEN"]
        config.access_token_secret = ENV["HUMAN_ACCESS_TOKEN_SECRET"]
      end
      @redis = Redis.new(url: ENV["REDISTOGO_URL"])
    end

    def train_scheduler
      ensure_trained_only_once("scheduler") do
        # User timeline API returns only up to 3,200 tweets
        options = { count: 200 }
        16.times do
          tweets = @client.user_timeline(options)
          tweets.each do |tweet|
            train_tweet(tweet)
          end
          options[:max_id] = tweets.last.id - 1
        end
      end
    end

    def train_tweet(tweet)
      attributes = {}
      attributes[:tweet_id] = tweet.id
      attributes[:text] = tweet.text
      attributes[:minute] = tweet.created_at.hour * 60 + tweet.created_at.min
      attributes[:created_at] = tweet.created_at

      unless tweet.in_reply_to_user_id.nil?
        attributes[:reply_user_id] = tweet.in_reply_to_user_id
      end

      Tweet.create(attributes)
    end

    def train_classifier
      ensure_trained_only_once("classifier") do
        @favorite_ids = []
        @classifier = Classifier.new
        train_favorites
        train_normals
      end
    end

    private

    def ensure_trained_only_once(key, &block)
      return if @redis.exists("trained:#{key}")
      block.call
      @redis.set("trained:#{key}", true)
    end

    def train_favorites
      options = { count: 100 }
      8.times do
        tweets = @client.favorites(options)
        tweets.each do |tweet|
          @favorite_ids << tweet.id
          @classifier.train(tweet, :favorite)
        end
        options[:max_id] = tweets.last.id - 1
      end
    end

    def train_normals
      options = { count: 100 }
      8.times do
        tweets = @client.home_timeline(options)
        tweets.each do |tweet|
          next if @favorite_ids.include?(tweet.id)
          @classifier.train(tweet, :normal)
        end
        options[:max_id] = tweets.last.id - 1
      end
    end
  end
end