module MiT
  class Tweet < Sequel::Model
    def self.sample_by_minute(min: 0, max: 24 * 60)
      self.where(minute: min..max).to_a.sample
    end
  end
end