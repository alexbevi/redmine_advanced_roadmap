require_dependency "versions_controller"

module AdvancedRoadmap
  module VersionsControllerPatch
    def self.included(base)
      base.class_eval do
        
      
    
        def index_with_plugin
          #index_without_plugin
          @trackers = @project.trackers.find(:all, :order => 'position')
          retrieve_selected_tracker_ids(@trackers, @trackers.select {|t| t.is_in_roadmap?})
          @with_subprojects = params[:with_subprojects].nil? ? Setting.display_subprojects_issues? : (params[:with_subprojects] == '1')
          project_ids = @with_subprojects ? @project.self_and_descendants.collect(&:id) : [@project.id]

          @versions = @project.shared_versions || []
          @versions += @project.rolled_up_versions.visible if @with_subprojects
          @versions = @versions.uniq.sort
          @versions.reject! {|version| version.closed? || version.completed? } unless params[:completed]

          @issues_by_version = Hash.new
          version_ids = []
          issue_status_ids = {}
          issue_project_ids = {}
          issue_user_ids = {}
          issue_category_ids = {}
          issue_tracker_ids = {}
          
          unless @selected_tracker_ids.empty?
            @versions.each do |version|
              version_ids << version.id
              # Keep this here to at least render for now.
              @issues_by_version[version] = Array.new
            end
          end
          @versions.reject! {|version| !project_ids.include?(version.project_id) && @issues_by_version[version].blank?}
          
          # If you can cleanly replace the upcoming SQL with ActiveBase, be my guest. :)
          status = IssueStatus.default
          priority = IssuePriority.default
          version_string = version_ids.map { |i| i.to_s }.join(",")
          sql = "SELECT #{Issue.table_name}.*, SUM(#{TimeEntry.table_name}.hours) AS spent_hours"
          sql += " FROM #{Issue.table_name}"
          sql += " LEFT JOIN #{TimeEntry.table_name}"
          sql += "  ON #{Issue.table_name}.id = #{TimeEntry.table_name}.issue_id"
          sql += " WHERE fixed_version_id IN ("+version_string+")"
          sql += " GROUP BY #{Issue.table_name}.id"
          rows = ActiveRecord::Base.connection.select_all(sql)
          rows.each do |row|
            tempIssue = Issue.new(:status => status, :priority => priority)
            tempIssue.id = row['id']
            tempIssue.subject = row['subject']
            tempIssue.tracker_id = row['tracker_id']
            tempIssue.status_id = row['status_id']
            tempIssue.project_id = row['project_id']
            tempIssue.assigned_to_id = row['assigned_to_id']
            tempIssue.fixed_version_id = row['fixed_version_id'].to_i
            tempIssue.category_id = row['category_id']
            tempIssue.start_date = row['start_date']
            tempIssue.due_date = row['due_date']
            tempIssue.estimated_hours = row['estimated_hours'].to_f
            tempIssue.spent_hours = row['spent_hours'].to_f
            tempIssue.done_ratio = row['done_ratio']
            tempIssue.soonest_start = tempIssue.start_date
            
            if !issue_status_ids.include?(tempIssue.status_id)
              issue_status_ids[tempIssue.status_id] = IssueStatus.new
            end
            tempIssue.status = issue_status_ids[tempIssue.status_id]
            
            if !issue_project_ids.include?(tempIssue.project_id)
              issue_project_ids[tempIssue.project_id] = Project.new
            end
            tempIssue.project = issue_project_ids[tempIssue.project_id]
            
            if !issue_tracker_ids.include?(tempIssue.tracker_id)
              issue_tracker_ids[tempIssue.tracker_id] = Tracker.new
            end
            tempIssue.tracker = issue_tracker_ids[tempIssue.tracker_id]
            
            if !tempIssue.assigned_to_id.nil?
              if !issue_user_ids.include?(tempIssue.assigned_to_id)
                issue_user_ids[tempIssue.assigned_to_id] = User.new()
              end
              tempIssue.assigned_to = issue_user_ids[tempIssue.assigned_to_id]
            end
            
            if !tempIssue.category_id.nil?
              if !issue_category_ids.include?(tempIssue.category_id)
                issue_category_ids[tempIssue.category_id] = IssueCategory.new
              end
            end
            tempIssue.category = issue_category_ids[tempIssue.category_id]
            
            @versions.each do |version|
              if version.id == tempIssue.fixed_version_id
                if !@issues_by_version[version].nil?
                  @issues_by_version[version] << tempIssue
                  version.issueCache(tempIssue)
                  version.fixed_issues << tempIssue
                  #tempIssue.fixed_version = version
                  #tempIssue.assignable_versions = [version]
                  #tempIssue.fixed_version_id = version.id
                  #tempIssue.fixed_version_id_was = version.id
                  break
                end
              end
            end
          end
          
          issue_status_string = issue_status_ids.map { |k,v| k.to_s }.join(",")
          sql = "SELECT *"
          sql += " FROM #{IssueStatus.table_name}"
          sql += " WHERE id IN ("+issue_status_string+")"
          rows = ActiveRecord::Base.connection.select_all(sql)
          rows.each do |row|
            issueStatus = issue_status_ids[row['id'].to_i]
            issueStatus.name = row["name"]
            issueStatus.is_closed = row["is_closed"]
          end
          
          issue_project_string = issue_project_ids.map { |k,v| k.to_s }.join(",")
          sql = "SELECT *"
          sql += " FROM #{Project.table_name}"
          sql += " WHERE id IN ("+issue_project_string+")"
          rows = ActiveRecord::Base.connection.select_all(sql)
          rows.each do |row|
            issueProject = issue_project_ids[row['id'].to_i]
            issueProject.id = row['id'].to_i
            issueProject.name = row['name']
            issueProject.identifier = row['identifier']
            issueProject.status = row['status'].to_i
            issueProject['rgt'] = row['rgt']
            issueProject['lft'] = row['lft']
            issueProject.shared_versions.open
          end
          
          
          issue_user_string = issue_user_ids.map { |k,v| k.to_s }.join(",")
          if(issue_user_string.length > 0)
            sql = "SELECT *"
            sql += " FROM #{User.table_name}"
            sql += " WHERE id IN ("+issue_user_string+")"
            rows = ActiveRecord::Base.connection.select_all(sql)
            rows.each do |row|
              issueUser = issue_user_ids[row['id'].to_i]
              issueUser.id = row['id']
              issueUser.firstname = row['firstname']
              issueUser.lastname = row['lastname']
              issueUser.type = row['type']
              issueUser.login = row['login']
              issueUser.mail = row['mail']
            end
          end
          
          issue_category_string = issue_category_ids.map { |k,v| k.to_s }.join(",")
          if(issue_category_string.length > 0)
            sql = "SELECT *"
            sql += " FROM #{IssueCategory.table_name}"
            sql += " WHERE id IN ("+issue_category_string+")"
            rows = ActiveRecord::Base.connection.select_all(sql)
            rows.each do |row|
              issueCategory = issue_category_ids[row['id'].to_i]
              issueCategory.name = row['name']
            end
          end
          
          issue_tracker_string = issue_tracker_ids.map { |k,v| k.to_s }.join(",")
          if(issue_category_string.length > 0)
            sql = "SELECT *"
            sql += " FROM #{Tracker.table_name}"
            sql += " WHERE id IN ("+issue_tracker_string+")"
            rows = ActiveRecord::Base.connection.select_all(sql)
            rows.each do |row|
              issueTracker = issue_tracker_ids[row['id'].to_i]
              issueTracker.name = row['name']
            end
          end
                    
          @totals = Version.calculate_totals(@versions)
          Version.sort_versions(@versions)
        end
        alias_method_chain :index, :plugin
    
        def show
          @issues = @version.sorted_fixed_issues
        end
      end
    end
  end
end
