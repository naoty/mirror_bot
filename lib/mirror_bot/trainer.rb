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
    end

    def train_scheduler
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

    def train_tweet(tweet)
      minute = tweet.created_at.hour * 60 + tweet.created_at.min
      Tweet.create(tweet_id: tweet.id, text: tweet.text, minute: minute)
    end

    def train_classifier
      @favorite_ids = []
      @classifier = Classifier.new
      train_favorites
      train_normals
    end

    private

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