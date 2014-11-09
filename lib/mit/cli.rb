require "thor"

module MiT
  class CLI < Thor
    module Subcommand
      class Train < Thor
        desc "classifier", "Train mit's classifier"
        def classifier
          Trainer.new.train_classifier
        end

        desc "scheduler", "Train mit's scheduler"
        def scheduler
          Trainer.new.train_scheduler
        end
      end
    end

    desc "start", "Start mit"
    def start
      threads = []
      threads << Thread.new { Bot.new.start }
      threads << Thread.new { Human.new.start }
      threads.each(&:join)
    end

    desc "train", "Train mit"
    subcommand "train", Subcommand::Train
  end
end