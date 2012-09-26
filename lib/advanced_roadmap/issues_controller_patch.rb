require_dependency "issues_controller"

module AdvancedRoadmap
  module IssuesControllerPatch
    def self.included(base)
      base.class_eval do
  
      protected
  
        def render(options = nil, extra_options = {}, &block)
          super(options, extra_options)
        end
  
      end
    end
  end
end
