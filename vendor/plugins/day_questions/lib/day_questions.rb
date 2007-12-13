module PluginAWeek #:nodoc:
  module CoreExtensions #:nodoc:
    module Date #:nodoc:
      module DayQuestions
        # Is it yesterday?
        def yesterday?
          self == 1.day.ago.to_date
        end
        
        # Is it today?
        def today?
          self == self.class.today
        end
        
        # Is it tomorrow?
        def tomorrow?
          self == 1.day.from_now.to_date
        end
        
        # Is it yesterday, today, or tomorrow?  For example,
        # 
        #   >> 2.days.ago.around_today?       # => false
        #   >> 1.day.ago.around_today?        # => true
        #   >> Time.now.around_today?         # => true
        #   >> 1.day.from_now.around_today?   # => true
        #   >> 2.days.from_now.around_today?  # => false
        def around_today?
          yesterday? || today? || tomorrow?
        end
        
        # The human day defines a value based on whether the Date is around the
        # current day.  If the Date is not around today, then the argument
        # passed in will be used.  The default for this value is "on month/day".
        # 
        # For example, if today is 12/31/2006:
        # 
        #   >> 2.days.ago.human_day             # => "on 12/31"
        #   >> 1.day.ago.human_day              # => "Yesterday"
        #   >> Time.now.human_day               # => "Today"
        #   >> 1.day.from_now.human_day         # => "Tomorrow"
        #   >> 2.days.from_now.human_day('%a')  # => "Sun"
        def human_day(value_if_not_around_today = "#{month}/#{day}")
          if today?
            "Today"
          elsif yesterday?
            "Yesterday"
          elsif tomorrow?
            "Tomorrow"
          else
            strftime(value_if_not_around_today)
          end
        end
      end
    end
    
    module Time #:nodoc:
      module DayQuestions
        delegate  :yesterday?,
                  :today?,
                  :tomorrow?,
                  :around_today?,
                  :human_day,
                    :to => :to_date
      end
    end
  end
end

::Date.class_eval do
  include PluginAWeek::CoreExtensions::Date::DayQuestions
end

::Time.class_eval do
  include PluginAWeek::CoreExtensions::Time::DayQuestions
end
