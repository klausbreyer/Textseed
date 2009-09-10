class UsersController < ApplicationController
  # Be sure to include AuthenticationSystem in  Application Controller instead
  include AuthenticatedSystem
  before_filter :login_required, :only => [:profile]

  def show
    @user = User.find(params[:id])
    @public_projects = Project.find_all_by_user_id_and_public(params[:id], true).length
    @private_projects = Project.find_all_by_user_id_and_public(params[:id], false).length

    @public_changes = 0
    @private_changes = 0
    @changes = []
    changes = Unit.find_all_by_user_id(params[:id])
    changes.each do |change|
      if change.project.public
        @public_changes +=1
        @changes << change
      else
        @private_changes += 1
      end
      
    end
    
    @projects = Project.find_all_by_user_id_and_public(params[:id], true, :limit => 5, :order => "created_at DESC")
    @changes = @changes[0..4]

    #last 10 day activity
    data = []
    labels = []
    20.downto(0) do |i|
      ober = (i-1).days.until(Date.today.midnight)
      unter = i.days.until(Date.today.midnight)
      data << Unit.find_all_by_user_id(params[:id], :conditions => ["created_at > :unter and created_at < :ober ", {:unter => unter, :ober => ober}]).length
      labels << i.days.until(Date.today.midnight).to_date.to_s(:short)
    end

    @activity = GoogleChart.new
    @activity.type = :line
    @activity.height = 200
    @activity.width = 920
    @activity.data = data
    @activity.labels = labels
    @activity.title = "Overall last 20 days activity"

    @activity = @activity.to_url
  end

  def index
    @users = User.all
  end

  def new
  end




  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with 
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    @user = User.new(params[:user])
    # @user.color = COLORS[rand(COLORS.length)] #choose a custom color for him

    @user.save
    if @user.errors.empty?
      # self.current_user = @user
      redirect_back_or_default('/')
      flash[:notice] = "Thanks for signing up! You received an email with an link to complete your activation"
    else
      flash[:error]  = "We couldn't set up that account, sorry.  Please try again, or contact an admin."
      render :action => 'new'
    end
  end

  def activate
    self.current_user = params[:activation_code].blank? ? false : User.find_by_activation_code(params[:activation_code])
    if logged_in? && !current_user.active?
      current_user.activate
      flash[:notice] = "Signup complete!"
    end
    redirect_back_or_default('/')
  end
  #
  # Change user passowrd
  def profile
    @user = User.find(session[:user_id])
  end


  def change_options_update
    @user = User.find(session[:user_id])
    if params[:want_mail]
      @user.want_mail = true
    else
      
      @user.want_mail = false
    end
    if @user.save
      flash[:notice] = 'Options are successfully updated.'
      redirect_to :action => :profile
    else
      flash[:alert] = "An error occured"
      redirect_to :action => :profile
    end
  end
  
  def change_username_update
    @user = User.find(session[:user_id])
    @user.login = params[:username]
    if @user.save
      flash[:notice] = 'Username was successfully updated.'
      redirect_to :action => :profile
    else
      flash[:alert] = "Username allready taken!"
      redirect_to :action => :profile
    end
  end

  def change_password_update
    return unless request.post?
    if User.authenticate(current_user.email, params[:old_password])
      if ((params[:password] == params[:password_confirmation]) &&
            !params[:password_confirmation].blank?)
        current_user.password_confirmation = params[:password_confirmation]
        current_user.password = params[:password]

        if current_user.save
          flash[:notice] = "Password successfully updated"

          redirect_to :action => :profile
        else
          flash[:alert] = "Password not changed"
          redirect_to :action => :profile
        end

      else
        flash[:alert] = "New Password mismatch"
        @old_password = params[:old_password]
        redirect_to :action => :profile
      end
    else
      flash[:alert] = "Old password incorrect"
      redirect_to :action => :profile
    end
  end

  #gain email address
  def forgot_password
    return unless request.post?
    if @user = User.find_by_email(params[:user][:email])
      @user.forgot_password
      @user.save
      redirect_back_or_default('/')
      flash[:notice] = "A password reset link has been sent to your email address"
    else
      flash[:alert] = "Could not find a user with that email address"
    end
  end

  #reset password
  def reset_password
    @user = User.find_by_password_reset_code(params[:id])
    return if @user unless params[:user]

    if ((params[:user][:password] && params[:user][:password_confirmation]) &&
          !params[:user][:password_confirmation].blank?)
      self.current_user = @user #for the next two lines to work
      current_user.password_confirmation = params[:user][:password_confirmation]
      current_user.password = params[:user][:password]
      @user.reset_password
      flash[:notice] = current_user.save ? "Password reset success." : "Password reset failed."
      redirect_back_or_default('/')
    else
      flash[:alert] = "Password mismatch"
    end
  end
  
end
