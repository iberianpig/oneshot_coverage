module OneshotCoverage
  module SidekiqMiddleware
    class Server
      def call(worker, msg, queue)
        yield
      ensure
        if Coverage.running?
          OneshotCoverage.emit
        end
      end
    end
  end
end
