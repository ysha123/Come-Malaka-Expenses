class EventsController < ApplicationController

  before_action :authenticate_user!

  ensure_authorization_performed

  authorize_actions_for Event


  def index
    @events = Event.order_by(:value_date => 'desc').with_role(:event_participant, current_user)
  end


  def new
    @event = Event.new(from_date: Date.current, end_date: Date.current+3.days, organizer_id: current_user.id)
    authorize_action_for @event
  end


  def create
    @event = Event.create(event_params)
    @event.add_participant current_user
    if @event.invalid? then
      flash[:notice] = "Event is invalid. Please correct."
      render :new and return
    end
    @event.save
    flash[:notice] = "Event created."
    redirect_to events_path
  end


  def edit
    @event = Event.find params[:id]
    authorize_action_for(@event)
  end


  def update
    @event = Event.find params[:id]
    @event.update_attributes event_params if authorize_action_for(@event)
    if @event.invalid? then
      flash[:notice] = "Event cannot be updated with invalid data. Please correct."
      render :edit and return
    end
    flash[:notice] = "Event updated."
    redirect_to events_path
  end


  def destroy
    event = Event.find(params[:id])
    if event.items.count == 0  then
      event.destroy if authorize_action_for(event)
      flash[:notice] = "Event deleted."
    else
      flash[:notice] = "Event cannot be deleted. Posted items exist."
      redirect_back(fallback_location: root_path) and return
    end
	  redirect_to events_path
  end


  def show
    @event = Event.find params[:id]
    authorize_action_for(@event)
  end


  def event_all_items
    @event = Event.find(params[:event_id])
    authorize_action_for(@event)
    @items = @event.items.order_by(:value_date => 'desc')
  end


  def expense_report
    @event = Event.find(params[:event_id])
    authorize_action_for(@event)
    @participants = @event.users
    @items = @event.items
  end

  def who_owes_you
    init_actions
    @event.who_owes current_user, @total_amounts, @item_lists
  end

  def you_owe_whom
    init_actions
    @event.who_paid_for current_user, @total_amounts, @item_lists
  end

  private

  def init_actions
    @event = Event.find(params[:event_id])
    authorize_action_for(@event)
    @total_amounts = Hash.new { |h,k| h[k] = 0 }
    @item_lists = Hash.new { |h,k| h[k] = [] }
  end

  def event_params
  	params.require(:event).permit(:name, :from_date, :end_date, :description, :organizer_id, :event_currency, :user_ids => [], :users => [])
  end

end
