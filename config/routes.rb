if Gem::Version.new("3.0") > Gem::Version.new(Rails.version) then
  ActionController::Routing::Routes.draw do |map|
    map.connect 'projects/:id/milestones/:action', :controller => 'milestones'
    map.connect 'milestones/:action', :controller => 'milestones'
  end
else
  RedmineApp::Application.routes.draw do
    match 'projects/:id/milestones/:action', :to => 'milestones'
    match 'milestones/:action', :controller => 'milestones'
  end
end