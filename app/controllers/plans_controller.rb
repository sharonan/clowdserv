class PlansController < ApplicationController
  include ApplicationHelper
  before_action :set_event, only: [:new, :create]
  before_action :must_be_able_to_view_event, only: [:new, :create]

  # GET /plans

  # GET /plans/new
  def new
    @event = Event.find_by_id(params[:event_id])
    @plan = Plan.new(:event_id => @event, :id => SecureRandom.uuid)
  end


  # POST /plans
  # POST /plans.json
  def create
    @event = Event.find_by_id(params[:event_id])
    if params[:plan][:dtstart].is_a? String
      dtstart =  DateTime.parse(params[:plan][:dtstart])
    else
      dtstart = params[:plan][:dtstart]
    end
    @plan = Plan.create(:title => params[:plan][:title], :location => params[:plan][:location], 
      :location_title => params[:plan][:location_title], :event_id => @event.id,
      :dtstart => dtstart, :duration => params[:plan][:duration],
      :latitude => params[:plan][:latitude], :longitude => params[:plan][:longitude],
      :id => SecureRandom.uuid)
    
    respond_to do |format|
      format.html { redirect_to @event, notice: 'Plan was successfully created.' }
      format.json { render :text => "OK", :status => 200 }
    end
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_plan
      @plan = Plan.find_by_id(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def plan_params
      params.require(:plan).permit(:location, :location_lat, :location_lng, :location_title, :dtstart, :duration, :title)
    end
end
