require "okura/serializer"
require "redis"

module MiT
  class Classifier
    CATEGORIES = %i(normal favorite).freeze
    FAVORITE_THRESHOLD = 3

    def initialize
      dictionary_path = File.expand_path("../../assets/okura-dic", __dir__)
      @tagger = Okura::Serializer::FormatInfo.create_tagger(dictionary_path)
      @redis = Redis.new(url: ENV["REDISTOGO_URL"])
    end

    def classify(tweet)
      favorite_probability = calculate_probability(tweet, :favorite)
      normal_probability = calculate_probability(tweet, :normal)
      favorite_probability > normal_probability * FAVORITE_THRESHOLD ? :favorite : :normal
    end

    def train(tweet, category)
      features = parse_into_features(tweet.text)
      features << tweet.user.screen_name
      features.each { |feature| train_feature_and_category(feature, category) }
    end

    private

    def parse_into_features(text)
      nodes = @tagger.parse(text)
      words = nodes.mincost_path.map(&:word).uniq
      words.select { |word| word.left.text =~ /名詞/ }.map(&:surface)
    end

    def train_feature_and_category(feature, category)
      increment_feature_and_category(feature, category)
      increment_category(category)
      if category == :favorite
        decrement_feature_and_category(feature, :normal)
        decrement_category(:normal)
      end
    end

    def increment_feature_and_category(feature, category)
      key = "features:#{feature}"
      field = "categories:#{category}"

      if !@redis.exists(key) || !@redis.hexists(key, field)
        @redis.hset(key, field, 0)
      end
      @redis.hincrby(key, field, 1)
    end

    def increment_category(category)
      key = "categories:#{category}"
      @redis.set(key, 0) unless @redis.exists(key)
      @redis.incr(key)
    end

    def decrement_feature_and_category(feature, category)
      key = "features:#{feature}"
      field = "categories:#{category}"

      return unless @redis.exists(key)
      return unless @redis.hexists(key, field)
      return if @redis.hget(key, field).to_i < 1
      @redis.hdecrby(key, field, 1)
    end

    def decrement_category(category)
      key = "categories:#{category}"
      return unless @redis.exists(key)
      return if @redis.get(key).to_i < 1
      @redis.decr(key)
    end

    def calculate_probability(tweet, category)
      features = parse_into_features(tweet.text)
      features << tweet.user.screen_name
      accumulated_probability = features.reduce(1) do |p, feature|
        p *= calculate_feature_probability(feature, category)
      end
      category_probability = calculate_category_probability(category)
      accumulated_probability * category_probability
    end

    def calculate_feature_probability(feature, category)
      features_key = "features:#{feature}"
      categories_key = "categories:#{category}"

      return 0 unless @redis.exists(features_key)
      return 0 unless @redis.hexists(features_key, categories_key)
      return 0 if @redis.get(categories_key).to_i == 0
      @redis.hget(features_key, categories_key).to_f / @redis.get(categories_key).to_i
    end

    def calculate_category_probability(category)
      key = "categories:#{category}"
      @redis.get(key).to_f / total_feature_count
    end

    def total_feature_count
      CATEGORIES.inject(0) do |count, category|
        key = "categories:#{category}"
        count += @redis.get(key).to_i
      end
    end
  end
end