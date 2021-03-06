require 'spec/runner/formatter/base_text_formatter'

module Spec
  module Runner
    module Formatter
      class ProgressBarFormatter < BaseTextFormatter
        def example_failed(example, counter, failure)
          @output.print colourise('F', failure)
          @output.flush
        end

        def example_passed(example)
          @output.print green('.')
          @output.flush
        end
      
        def example_pending(example_group_description, example_name, message)
          super
          @output.print yellow('P')
          @output.flush
        end
        
        def start_dump
          @output.puts
          @output.flush
        end
      end
    end
  end
end
