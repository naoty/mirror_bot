require "twitter"

module MiT
  class Bot
    def initialize
      @streaming_client = Twitter::Streaming::Client.new do |config|
        config.consumer_key = ENV["BOT_CONSUMER_KEY"]
        config.consumer_secret = ENV["BOT_CONSUMER_SECRET"]
        config.access_token = ENV["BOT_ACCCESS_TOKEN"]
        config.access_token_secret = ENV["BOT_ACCESS_TOKEN_SECRET"]
      end
    end

    def start
      @streaming_client.user do |object|
        case object
        when Twitter::Tweet
          # TODO: Classify and favorite a tweet
        end
      end
    end
  end
end