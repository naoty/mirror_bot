require "thor"

module MiT
  class CLI < Thor
    module Subcommand
      class Train < Thor
        desc "classifier", "Train mit's classifier"
        def classifier
          # TODO: Train classifier
          puts "train mit's classifier!"
        end

        desc "scheduler", "Train mit's scheduler"
        def scheduler
          # TODO: Train scheduler
          puts "train mit's scheduler!"
        end
      end
    end

    desc "start", "Start mit"
    def start
      # TODO: Start human client and bot client on multi-thread
      puts "mit start!"
    end

    desc "train", "Train mit"
    subcommand "train", Subcommand::Train
  end
end