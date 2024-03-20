module Vineti::Notifications
  module StepMacro
    SymbolizeKeys = lambda do |(ctx), *|
      ctx[:params] = ctx[:params].deep_symbolize_keys
    end

    IterationWrapper = Class.new do
      def self.call((options), *, &block)
        options[:count].to_i.times do |index|
          options[:index] = index
          signal, (ctx, flow_options) = yield
          success = signal.inspect.eql?(%(#<Trailblazer::Activity::End semantic=:success>))
          result = success ? Trailblazer::Operation::Railway.pass! : Trailblazer::Operation::Railway.fail!

          return [result, [ctx || options, flow_options]] unless success
        end
        Trailblazer::Operation::Railway.pass!
      end
    end
  end
end
