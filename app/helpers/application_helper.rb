# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def german_time(time)
    time.strftime("%d.%m.%Y %H:%M")  unless time.nil?
  end

  def user_logged_in?
    session[:user_id]
  end
end
