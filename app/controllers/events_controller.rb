class EventsController < ApplicationController
  include ApplicationHelper

  before_action :set_event, only: [:show, :edit, :update, :destroy]
  before_action :must_be_able_to_view_event, except: [:index, :idindex, :new, :create]
  before_action :must_match_user, only: [:index]
  
  # GET /user/33333/events
  # GET /users/333333/events.json
  def index
      
    @events = current_user.events
    
    
    respond_to do |format|
      format.html {}
      format.json { render json: Event.events_to_json(@events) }
    end
  end
  
  def idindex
    @event_ids = Attendance.where(:id => params[:user_id]).all.map {|a| a.event_id}
    respond_to do |format|
      format.html {}
      format.json {render json: {event_ids: @event_ids}}
    end
  end
    

  # GET /events/1
  # GET /events/1.json
  def show
    @plans = @event.plans
    
    respond_to do |format|
      format.html {}
      format.json { render json: @event.to_json}
    end
  end

  # GET /events/new
  def new
    @event = Event.new
  end

  # GET /events/1/edit
  def edit
  end

  # POST /events
  # POST /events.json
  def create
    @event = Event.new(event_params)
    @event.id = SecureRandom.uuid
    @event.phone_number = @the_user.phone_number
    Attendance.create(:id => @the_user.phone_number, :event_id => @event.id)
    
    respond_to do |format|
      if @event.save
        format.html { redirect_to @event, notice: 'Event was successfully created.' }
        format.json { render action: 'show', status: :created, location: @event }
      else
        format.html { render action: 'new' }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /events/1
  # PATCH/PUT /events/1.json
  def update
    @event.title = event_params['title']
    respond_to do |format|
      if @event.save
        format.html { redirect_to @event, notice: 'Event was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # LMD TODO: Disable DELETE on production site only; leave enabled on dev/test
  # DELETE /events/1
  # DELETE /events/1.json
  def destroy
    attendances = Attendance.where(:event_id => @event.id).map { |a| a }
    messages = @event.messages
    logger.info "Deleting event #{@event.id} and #{attendances.length} attendance records"
    @event.destroy
    attendances.each { |a| a.destroy }
    messages.each { |m| m.destroy }
    respond_to do |format|
      format.html { redirect_to :back }
      format.json { head :no_content }
    end
  end

  private

    # Never trust parameters from the scary internet, only allow the white list through.
    def event_params
      params.require(:event).permit(:title, :status)
    end
    
    def must_match_user
      if params[:user_id] != current_user.phone_number
        head :forbidden
      end
    end
    
end
