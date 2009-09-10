require 'RedCloth'
class ProjectsController < ApplicationController
  # GET /projects
  # GET /projects.xml
  before_filter :login_required, :except => [:index, :show]
  before_filter :project_consumer_check, :except  => [:index, :new, :create]
  before_filter :project_owner_check, :only => [:edit, :update, :destroy]
  
  include ERB::Util
  include ActionView::Helpers::AssetTagHelper

  def share
    @project = Project.find(params[:id])
  end
  def invite_consumer
    @project = Project.find(params[:id])
    emails_raw = params[:emails].split(" ").map do |email|
      email = email.strip  if email =~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
    end
    emails = emails_raw.compact.uniq
    to_invite = []
    to_grant = []
    emails.each do |email|
      user = User.find_by_email(email)
      if user
        grants_for_project = Consumer.find_all_by_user_id_and_project_id(user.id,params[:id])
        to_grant << user unless grants_for_project.length > 0
      else
        to_invite << email
      end
    end
    pp to_grant
    pp to_invite
    #first create user
    to_invite.each do |email|
      pass = Time.now.to_s + rand(1000000).to_s
      pass = Digest::MD5.hexdigest(pass)
      pass = pass[0,8]
      px = {"password_confirmation" => pass, "password" => pass, "login" => email, "email" => email}
      newuser = User.new(px)
      newuser.save
      to_grant << newuser
      UserMailer.deliver_inform(newuser, User.find(session[:user_id]), @project)
    end
    pp to_grant

    to_grant.each do |user|
      pp user
      consumer = Consumer.new
      consumer.project_id = @project.id
      consumer.user_id = user.id
      consumer.save
    end

    #then grant access for all user in once
    #redirect_to :action => :share
    
  end

  
  def index
    @projects = Project.find_all_by_public(true, :order => "updated_at desc")
    @private = Project.find_all_by_public(false, :order => "updated_at desc")
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @projects }
    end
  end

  # GET /projects/1
  # GET /projects/1.xml
  def show
    @project = Project.find(params[:id])
    @units = Unit.find_all_by_project_id(params[:id], :order => "created_at desc")

    @editor = User.find(@project.edited_by) if @project.edited_by && Time.now.to_s(:db).to_s.to_time < 5.minutes.since(@project.edited_at).to_s.to_time

    if params[:version]
      @unit = Unit.find(params[:version])
      unless @unit.project_id == @project.id
        redirect_to :back
        return
      end
    else
      @unit = @units.first
    end

    if @unit
      #build userlist
      usera = []
      @units.each do |unit|
        if !usera.include?(unit.user_id)
          usera << unit.user_id
        end
      end
      @users = []
      usera.each do |user|
        @users << User.find(user)
      end
    end

    if @unit
      @text = @unit.render
    else
      @text = ""
    end

    

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @project }
    end
  end

  def change
    @unit = Unit.new(params[:unit])
    @unit.user_id = session[:user_id]

    last = Unit.find_by_project_id(params[:id], :order => "created_at desc")
    if last
      first_content = last.content
    else
      first_content = ""
    end
    second_content = @unit.content
    
    File.open("first", 'w') do |f|
      f.write(first_content)
    end
    File.open("second", 'w') do |f|
      f.write(second_content)
    end

    erg = `wdiff first second `

    if(request.host != "localhost")
      erg = erg.gsub("-]\n", "-]")
    end

    erg = erg.gsub("-]\r\n", "-]")  #normal fix i think
    erg = erg.gsub("-]{+", "-] {+") #bugged - dont know why.


    # the new

    #wort für wort wird durchgegangen vom neuen text. dann wird im alten array
    #wenn es gelöscht worden ist, bleibt es drin wird aber als gelöscht markiert.
    #wenn es alt ist wird solange der index erhöht bis das wort wieder passt ---------- lies sich nicht sauber tracken an welchem wort man war.
    #wenn es neu ist wird einfach das neue wort mit dem neuen user abgespeichert
    #todo: weg von @vars
    if last && last.echoe
      @old_array = last.echoe #old array is the old data - readed from the table.
    else
      @old_array = []
    end
    
    #splitting the result
    @outer = []
    @all = erg.split("\r\n")
    @all.each do |row|
      @outer << row.split(" ")
    end
    modus = 0
    userid = 0
    @result = []
    oi = 0      #oldindex - counts only when an old word is added.
    #by the oldindex we can grab back to the old text and insert the original user id
    @outer.each do |inner|
      inner.each do |row|
        if row[0,2] == "{+" #change mode and shorten the string
          modus = 1
          row = row[2..-1]
        elsif row[0,2] == "[-"  #same
          modus = -1
          row = row[2..-1]
        end
        #no elsif because the end of the string can be in the same word
        if row[-2,2] == "+}" || row[-2,2] == "-]" #short but dont change mode because this iteration should be done in the old mode
          row = row[0..-3 ]
          reset = true
        end
        #vielleicht hat der zu viele offset mi t der versetztheit des reset zu tun?
        if modus == 1 #if its an normal word or an deleted word (which is in the old array included), then increment the oldindex and use the old user id
          userid = session[:user_id]#
        else  #else its new
          while  oi < (@old_array.length-1) && @old_array[oi][0] != row
            oi+=1
          end
          if @old_array[oi]
            userid = @old_array[oi][1]
          else
            userid = session[:user_id]
          end
          
          # puts @old_array[oi][0] + "bei #{oi}"
          #oi+=1
        end
        @result << [row, userid, modus]

        if reset
          modus = 0
        end
      end
      @result << ["[br]", userid, modus]
    end

    @result.pop


    @unit.resolv = erg
    @unit.echoe = @result

    @unit.project.updated_at = Time.now
    @unit.project.edited_at = nil
    @unit.project.edited_by = nil
    @unit.project.save
    respond_to do |format|
      if @unit.save
        flash[:notice] = 'Changed!'
        format.html { redirect_to(@unit.project) }
      else
        format.html { render :action => "write" }
      end
    end
  end

  
  def new
    @project = Project.new
    @project.public = true

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @project }
    end
  end

  # GET /projects/1/edit
  def edit
    @project = Project.find(params[:id])
    @units = Unit.find_all_by_project_id(params[:id])

  end

  # POST /projects
  # POST /projects.xml
  def create
    @project = Project.new(params[:project])
    @project.user_id = session[:user_id]

    respond_to do |format|
      if @project.save
        flash[:notice] = 'Project was successfully created.'
        format.html { redirect_to(@project) }
        format.xml  { render :xml => @project, :status => :created, :location => @project }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @project.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /projects/1
  # PUT /projects/1.xml
  def update
    @project = Project.find(params[:id])

    respond_to do |format|
      if @project.update_attributes(params[:project])
        flash[:notice] = 'Project was successfully updated.'
        format.html { redirect_to(@project) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @project.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/1
  # DELETE /projects/1.xml
  def destroy
    @project = Project.find(params[:id])
    @project.destroy

    respond_to do |format|
      format.html { redirect_to(projects_url) }
      format.xml  { head :ok }
    end
  end

  def write
    @project = Project.find(params[:id])
    @editor = User.find(@project.edited_by) if @project.edited_by && Time.now.to_s(:db).to_s.to_time < 5.minutes.since(@project.edited_at).to_s.to_time

    unless @editor
      @project.edited_by = session[:user_id]
      @project.edited_at = DateTime.now
      @project.save
    end

    last = Unit.find_by_project_id(params[:id], :order => "created_at desc")
    @unit = Unit.new(:project => @project)
    if last
      @unit.content = last.content
      @unit.resolv = last.resolv
    end

  end


end

