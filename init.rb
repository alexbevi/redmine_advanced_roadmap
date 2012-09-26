# This plugin should be reloaded in development mode.
if Rails.env.development? == "development"
  ActiveSupport::Dependencies.load_once_paths.reject!{|x| x =~ /^#{Regexp.escape(File.dirname(__FILE__))}/}
end
if Gem::Version.new("3.0") > Gem::Version.new(Rails.version) then
  require "redmine"
  require "dispatcher"
  require_dependency File.dirname(File.dirname(__FILE__)) + "/awesome_nested_set/rails/init"
end

require "rubygems"
require "gravatar"


if Gem::Version.new("3.0") > Gem::Version.new(Rails.version) then
  Dispatcher.to_prepare do 
    begin
      require_dependency "application"
    rescue LoadError
      require_dependency "application_controller"
    end

    ApplicationHelper.send(:include, AdvancedRoadmap::ApplicationHelperPatch)
    Issue.send(:include, AdvancedRoadmap::IssuePatch)
    IssuesController.send(:include, AdvancedRoadmap::IssuesControllerPatch)
    Project.send(:include, AdvancedRoadmap::ProjectPatch)
    ProjectsHelper.send(:include, AdvancedRoadmap::ProjectsHelperPatch)
    Redmine::I18n.send(:include, AdvancedRoadmap::RedmineI18nPatch)
    Version.send(:include, AdvancedRoadmap::VersionPatch)
    VersionsController.send(:include, AdvancedRoadmap::VersionsControllerPatch)
  end
else
  Rails.configuration.to_prepare do
    begin
      require_dependency "application"
    rescue LoadError
      require_dependency "application_controller"
    end

    ApplicationHelper.send(:include, AdvancedRoadmap::ApplicationHelperPatch)
    Issue.send(:include, AdvancedRoadmap::IssuePatch)
    IssuesController.send(:include, AdvancedRoadmap::IssuesControllerPatch)
    Project.send(:include, AdvancedRoadmap::ProjectPatch)
    ProjectsHelper.send(:include, AdvancedRoadmap::ProjectsHelperPatch)
    Redmine::I18n.send(:include, AdvancedRoadmap::RedmineI18nPatch)
    Version.send(:include, AdvancedRoadmap::VersionPatch)
    VersionsController.send(:include, AdvancedRoadmap::VersionsControllerPatch)
  end
end

require_dependency "advanced_roadmap/view_hooks"

#RAILS_DEFAULT_LOGGER.info "Advanced roadmap & milestones plugin for RedMine"

Redmine::Plugin.register :redmine_advanced_roadmap do
  name "Advanced Roadmap"
  url "https://bitbucket.org/StrangeWill/redmine-advanced-roadmap/"
  author "Emilio Gonzalez Montana, William Roush"
  author_url "https://bitbucket.org/StrangeWill/redmine-advanced-roadmap/"
  description "Additional performance metrics analysis for Redmine's Roadmap feature and support for project milestones."
  version "0.7.0"
  permission :manage_milestones, {:milestones => [:add, :edit, :destroy]}
  requires_redmine :version_or_higher => "1.0.2"

  
  settings  :default => {
    "parallel_effort_custom_field" => "",
    "solved_issues_to_estimate" => "5",
    "ratio_good" => "0.8",
    "color_good" => "green",
    "ratio_bad" => "1.2",
    "color_bad" => "orange",
    "ratio_very_bad" => "1.5",
    "color_very_bad" => "red"
  }, :partial => "settings/advanced_roadmap_settings"
end
