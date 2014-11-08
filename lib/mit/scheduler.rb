module MiT
  class Scheduler
    SCHEDULE_INTERVAL = 1 * 60

    def initialize
    end

    def start(&block)
      loop do
        block.call if on_time?
        sleep(SCHEDULE_INTERVAL)
      end
    end

    private

    def on_time?
      true
    end
  end
end