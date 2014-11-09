require "twitter"

module MiT
  class Human
    def initialize
      @streaming_client = Twitter::Streaming::Client.new do |config|
        config.consumer_key = ENV["HUMAN_CONSUMER_KEY"]
        config.consumer_secret = ENV["HUMAN_CONSUMER_SECRET"]
        config.access_token = ENV["HUMAN_ACCESS_TOKEN"]
        config.access_token_secret = ENV["HUMAN_ACCESS_TOKEN_SECRET"]
      end
      rest_client = Twitter::REST::Client.new do |config|
        config.consumer_key = ENV["HUMAN_CONSUMER_KEY"]
        config.consumer_secret = ENV["HUMAN_CONSUMER_SECRET"]
        config.access_token = ENV["HUMAN_ACCESS_TOKEN"]
        config.access_token_secret = ENV["HUMAN_ACCESS_TOKEN_SECRET"]
      end
      @user = rest_client.user(skip_status: true)
      @classifier = Classifier.new
      @trainer = Trainer.new
    end

    def start
      @streaming_client.user do |object|
        case object
        when Twitter::Tweet
          @trainer.train_tweet(object) if object.user.id == @user.id
          @classifier.train(object, :normal)
        when Twitter::Streaming::Event
          if object.name == :favorite
            @classifier.train(object.target_object, :favorite)
          end
        end
      end
    end
  end
end