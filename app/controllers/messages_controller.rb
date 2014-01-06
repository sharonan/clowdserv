class MessagesController < ApplicationController
  include ApplicationHelper
  before_action :set_event, only: [:new, :create]
  before_action :must_be_able_to_view_event, only: [:new, :create]


  def create
    @event = Event.find_by_id(params[:event_id])
    @message = Message.create(:content => params[:message][:content], :event_id => @event.id,
      :phone_number => @the_user.phone_number, :id => SecureRandom.uuid)
    
    respond_to do |format|
      format.html { redirect_to @event, notice: 'Message was successfully added.' }
      format.json { render :text => "OK", :status => 200 }
    end
  end


  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def plan_params
      params.require(:message).permit(:content)
    end
end
