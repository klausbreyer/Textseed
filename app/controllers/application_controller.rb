# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  include AuthenticatedSystem
  include ExceptionNotifiable
  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  def project_consumer arg = params[:id]
    project = Project.find(arg)
    puts 0
    puts project.public
    return true if project && (project.public == nil || project.public == true) #public projects can be viewed every time
    puts 1
    return false if session[:user_id]== nil || project == nil                                       #if the project is not public then the user has to be logged in
    puts 2
    return true if session[:user_id] == project.user_id   #or is owner
    puts 3
    return Consumer.find_all_by_user_id_and_project_id(session[:user_id],arg).length > 0#else it depends if there are rights for the user
  end

  def project_owner arg = params[:id]
    project = Project.find(arg)
    return false unless session[:user_id]
    return false unless project
    return session[:user_id] == project.user_id || session[:user_id] == 1
  end

  def project_owner_check
    redirect_back unless project_owner
  end

  def project_consumer_check
    redirect_back unless project_consumer
  end

  protected
  def redirect_back
    flash[:error] = "You are not allowed to see this document"
    redirect_to(root_path)
  end

end
