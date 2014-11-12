require "thor"

module MirrorBot
  class CLI < Thor
    module Subcommand
      class Train < Thor
        desc "classifier", "Train mirror_bot's classifier"
        def classifier
          Trainer.new.train_classifier
        end

        desc "scheduler", "Train mirror_bot's scheduler"
        def scheduler
          Trainer.new.train_scheduler
        end

        desc "clear", "Clear train data"
        def clear
          Trainer.new.clear
        end
      end
    end

    desc "start", "Start mirror_bot"
    def start
      threads = []
      threads << Thread.new { Bot.new.start }
      threads << Thread.new { Human.new.start }
      threads.each(&:join)
    end

    desc "train", "Train mirror_bot"
    subcommand "train", Subcommand::Train
  end
end