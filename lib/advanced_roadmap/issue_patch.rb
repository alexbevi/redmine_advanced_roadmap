require_dependency "issue"

module AdvancedRoadmap
  module IssuePatch
    def self.included(base)
      base.class_eval do
        # We can pre-fill this with a more efficient query to sum all hours.
        @spentHoursCache
        
        def soonest_start=(soonest)
          @soonest_start = soonest
        end
        
        def assignable_versions=(versions)
          @assignable_versions = versions
        end
        
        def spent_hours=(spent)
          @spentHoursCache = spent
        end
        
        def spent_hours
          if @spentHoursCache.nil?
            return 0 #self_and_descendants.sum("#{TimeEntry.table_name}.hours", :include => :time_entries).to_f || 0.0
          else
            return @spentHoursCache
          end
        end
                        
	      
        # Need to cache children
        def rest_hours
          if !@rest_hours
            @rest_hours = 0.0
            #if children.empty?
              if !(closed?)
                if (spent_hours > 0.0) && (done_ratio > 0.0)
                  if done_ratio < 100.0
                    @rest_hours = ((100.0 - done_ratio.to_f) * spent_hours.to_f) / done_ratio.to_f
                  end
                else
                  @rest_hours = ((100.0 - done_ratio.to_f) * estimated_hours.to_f) / 100.0
                end
              end
            #else
              #children.each do |child|
              #  @rest_hours += child.rest_hours
              #end
            #end
          end
          @rest_hours
        end
  
        def parents_count
          parent.nil? ? 0 : 1 + parent.parents_count
        end
        
  
        def estimated_hours
          super #if User.current.allowed_to?(:view_issue_estimated_hours, self.project)
        end
  
      end
    end
  end
end
