require_dependency "projects_controller"

module AdvancedRoadmap
  module ProjectPatch
    def self.included(base)
      base.class_eval do
        has_many :milestones
        
        def setrgt=(srgt)
          rgt = srgt
        end
        def setlgt=(slgt)
          lgt = slgt
        end
      end
    end
  end
end
