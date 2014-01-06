module ApplicationHelper
  def must_be_able_to_view_event
    raise "Cannot view event 1" if @event.nil?
    raise "Must be authenticated" if current_user.nil?
    organizer = @event.organizer
    
    if organizer != current_user && !(@event.attendees.include? current_user.phone_number)
      render :text => "Forbidden", :status => 401
    end
    
  end
  def set_event
    @event = Event.find_by_id(params[:id] || params[:event_id])
    if !@event 
      render :text => "404 Not Found", :status => 404
      return
    end
  end


end
