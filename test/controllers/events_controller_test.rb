require 'test_helper'

class EventsControllerTest < ActionController::TestCase
  include ApplicationHelper

	#Test data initialized in test_helper.rb#setup
	#and truncated while teardown

	def setup
		super
		sign_in @non_participant_user
	end

	def teardown
		super
		sign_out @non_participant_user
	end

  test "unauthenticated user for any event controller action must be redirected to sign in page" do

    sign_out @non_participant_user

    get :index
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to new_user_session_path, "Redirect must be new_user_session_path"

    get :show, params: { id: @event.id }
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to new_user_session_path, "Redirect must be new_user_session_path"

    get :edit, params: { id: @event.id }
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to new_user_session_path, "Redirect must be new_user_session_path"

    assert_no_difference('Event.count', "Event must not be created") do
      put :update, params: { id: @event.id }
    end
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to new_user_session_path, "Redirect must be new_user_session_path"

    get :new
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to new_user_session_path, "Redirect must be new_user_session_path"

    assert_no_difference('Event.count', "Event must not be created") do
      post :create
    end
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to new_user_session_path, "Redirect must be new_user_session_path"

    assert_no_difference('Event.count', "Event must not be created") do
      delete :destroy, params: { id: @event.id }
    end
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to new_user_session_path, "Redirect must be new_user_session_path"

    get :event_all_items, params: { event_id: @event.id }
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to new_user_session_path, "Redirect must be new_user_session_path"

    get :expense_report, params: { event_id: @event.id }
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to new_user_session_path, "Redirect must be new_user_session_path"
  end

  test "organizer can see events page" do
    sign_in @organizer
    get :index
    assert_response :success, "Response must be success"
    assert_template :index, "Index page must be rendered"
    assert_not_nil assigns(:events), "Events must be assigned"
    assert_equal 1, assigns(:events).length, "Event participant must see event"
  end

  test "participant can see events page" do
    sign_in @user1
    get :index
    assert_response :success, "Response must be success"
    assert_template :index, "Index page must be rendered"
    assert_not_nil assigns(:events), "Events must be assigned"
    assert_equal 1, assigns(:events).length, "Event participant must see event"
  end

  test "non participant can see events page" do
    get :index
    assert_response :success, "Response must be success"
    assert_not_nil assigns(:events), "Events must be assigned"
    assert_equal 0, assigns(:events).length, "Non participant must not see event"
  end

  test "organizer can see new page" do
    sign_in @organizer
    get :new
    assert_response :success, "Response must be success"
    assert_template :new, "New page must be rendered"
    assert_not_nil assigns(:event), "Event must be assigned"
  end

  test "participant can see new page" do
    sign_in @user1
    get :new
    assert_response :success, "Response must be success"
    assert_template :new, "New page must be rendered"
    assert_not_nil assigns(:event), "Event must be assigned"
  end

  test "non participant can see new page" do
    get :new
    assert_response :success, "Response must be success"
    assert_template :new, "New page must be rendered"
    assert_not_nil assigns(:event), "Event must be assigned"
  end

  test "user can create valid event and becomes participant" do
  	test_event = {name: "Test event", from_date: Date.current, end_date: Date.current+3, description: "Test description", 
  		event_currency: "eur", organizer_id: @non_participant_user.id}
  	assert_difference('Event.count', 1, "Event must be created") do
  		post :create, params: { event: test_event }
  	end
  	assert_response :redirect, "Response must be redirect"
  	assert_equal "Event created.", flash[:notice], "Flash[:notice] must state that event was created"
    assert_not_nil assigns(:event), "Event must be assigned"
  	assert_redirected_to events_path, "Redirect must be events_path"
  	assert_includes assigns(:event).users, @non_participant_user, "User must be participant of event"
    assert_equal @non_participant_user.id, assigns(:event).organizer_id, "Event organizer must be the event creator"
  end

  test "user tries to create event with invalid data and is sent back to new page" do
  	test_event = {name: nil}
  	post :create, params: { event: test_event }
  	assert_response :success, "Response must be success"
  	assert_template :new, "New page must be rendered"
  	assert_equal "Event is invalid. Please correct.", flash[:notice]
    assert_select "form div.row div.small-12.medium-8.large-6.columns.small-centered fieldset div.field.small-12.medium-4.large-4.columns.end .field_with_errors"
  end

  test "organizer can edit event" do
  	sign_in @organizer
  	get :edit, params: { id: @event.id }
  	assert_response :success, "Response must be success"
  	assert_template :edit, "Edit page must be rendered"
  	assert assigns(:event), "Event must be assigned"
  end

  test "participant cannot edit event" do
  	sign_in @user1
  	get :edit, params: { id: @event.id }
  	assert_response :forbidden, "Response must be forbidden"
  end

  test "non participant cannot edit event" do
  	get :edit, params: { id: @event.id }
  	assert_response :forbidden, "Response must be forbidden"
  end

  test "organizer can update event" do
  	sign_in @organizer
   	test_event = {name: "Randers", from_date: Date.new(2012, 11, 2), 
			end_date: Date.new(2012, 11, 4), description: "Come Malaka event in a different country", 
			event_currency: "eur", organizer_id: @organizer.id}
  	put :update, params: { id: @event.id, event: test_event }
  	assert_response :redirect, "Response must be redirect"
  	assert_redirected_to events_path, "Redirect must be events_path"
  	assert_equal "Event updated.", flash[:notice], "Flash[:notice] must state that event was updated"
  end

  test "organizer tries to update event with invalid data and is sent back to edit page" do
  	sign_in @organizer
   	test_event = {name: ""}
  	put :update, params: { id: @event.id, event: test_event }
  	assert_response :success, "Response must be success"
  	assert_template :edit, "Edit page must be rendered"
  	assert_equal "Event cannot be updated with invalid data. Please correct.", flash[:notice], "Flash[:notice] must state that event is invalid"
    assert_select "form div.row div.small-12.medium-8.large-6.columns.small-centered fieldset div.field.small-12.medium-4.large-4.columns.end .field_with_errors"
  end

  test "participant cannot update event" do
  	sign_in @user1
    test_event = {name: "Randers", from_date: Date.new(2012, 11, 2), 
			end_date: Date.new(2012, 11, 4), description: "Come Malaka event in a different country", 
			event_currency: "eur", organizer_id: @organizer.id}
  	put :update, params: { id: @event.id, event: test_event }
  	assert_response :forbidden, "Response must be forbidden"
  end

  test "non participant cannot update event" do
    test_event = {name: "Randers", from_date: Date.new(2012, 11, 2), 
			end_date: Date.new(2012, 11, 4), description: "Come Malaka event in a different country", 
			event_currency: "eur", organizer_id: @organizer.id}
  	put :update, params: { id: @event.id, event: test_event }
  	assert_response :forbidden, "Response must be forbidden"
  end

  test "organizer can delete event" do
  	sign_in @organizer
  	@event.items = [] #make event deletable by removing its items
  	assert_difference('Event.count', -1, "Event must be deleted") do
	  	delete :destroy, params: { id: @event.id }
  	end	
  	assert_response :redirect, "Response must be redirect"
  	assert_redirected_to events_path, "Redirect must be events_path"
  	assert_equal "Event deleted.", flash[:notice]
  end

  test "organizer must fail to delete an event that contains items" do
  	sign_in @organizer
    @request.env['HTTP_REFERER'] = 'http://foo.com'
  	assert_no_difference('Event.count', "Event must not be deleted") do
	  	delete :destroy, params: { id: @event.id }
  	end	
  	assert_response :redirect, "Response must be redirect"
  	assert_redirected_to "http://foo.com", "Redirect must be back (to HTTP_REFERER)"
  	assert_equal "Event cannot be deleted. Posted items exist.", flash[:notice], "Flash[:notice] must state that event cannot be deleted due to existing items"
  end

  test "participant cannot delete event" do
  	sign_in @user1
  	@event.items = [] #make event deletable by removing its items
    assert_no_difference('Event.count', "Event must not be deleted") do
      delete :destroy, params: { id: @event.id }
    end
    assert_response :forbidden, "Response must be forbidden"
  end

  test "non participant cannot delete event" do
  	@event.items = [] #make event deletable by removing its items
    assert_no_difference('Event.count', "Event must not be deleted") do
      delete :destroy, params: { id: @event.id }
    end
    assert_response :forbidden, "Response must be forbidden"
  end

  test "organizer can display event" do
  	sign_in @organizer
  	get :show, params: { id: @event.id }
  	assert_response :success, "Response must be success"
  	assert assigns(:event), "Event must be assigned"
  end

  test "event participant can display event" do
  	sign_in @user1
  	get :show, params: { id: @event.id }
  	assert_response :success, "Response must be success"
  	assert assigns(:event), "Event must be assigned"
  end

  test "non participant cannot display event" do
  	get :show, params: { id: @event.id }
  	assert_response :forbidden, "Response must be forbidden"
  end

  test "organizer can see all event items" do
  	sign_in @organizer
  	get :event_all_items, params: { event_id: @event.id }
  	assert_response :success, "Response must be success"
  	assert assigns(:items), "Items must be assigned"
  end

  test "participant can see all event items" do
  	sign_in @user1
  	get :event_all_items, params: { event_id: @event.id }
  	assert_response :success, "Response must be success"
  	assert assigns(:items), "Items must be assigned"
  end

  test "non participant cannot see all event items" do
  	get :event_all_items, params: { event_id: @event.id }
  	assert_response :forbidden, "Response must be forbidden"
  	assert_nil assigns(:items), "Items must not be assigned"
  end

  test "organizer can see expense report" do
  	sign_in @organizer
  	get :expense_report, params: { event_id: @event.id }
  	assert_response :success, "Response must be success"
  	assert assigns(:event), "Event must be assigned"
  	assert assigns(:participants), "Participants must be assigned"
  	assert assigns(:items), "Items must be assigned"
  end

  test "participant can see expense report" do
  	sign_in @user1
  	get :expense_report, params: { event_id: @event.id }
  	assert_response :success, "Response must be success"
  	assert assigns(:event), "Event must be assigned"
  	assert assigns(:participants), "Participants must be assigned"
  	assert assigns(:items), "Items must be assigned"  end

  test "non participant cannot see expense report" do
  	get :expense_report, params: { event_id: @event.id }
  	assert_response :forbidden, "Response must be forbidden"
  	assert_nil assigns(:participants), "Participants must not be assigned"
  	assert_nil assigns(:items), "Items must not be assigned"
  end

  test "organizer can see Who owes you? details" do
    sign_in @organizer
    get :who_owes_you, params: { event_id: @event.id }
    assert_response :success, "Response must be success"
    assert assigns(:event), "Event must be assigned"
    assert_not_empty assigns(:total_amounts), "Total amounts must not be empty"
    assert_not_empty assigns(:item_lists), "Item lists must not be empty"
  end

  test "participant (payer) can see Who owes you? details" do
    sign_in @user4
    get :who_owes_you, params: { event_id: @event.id }
    assert_response :success, "Response must be success"
    assert assigns(:event), "Event must be assigned"
    assert_not_empty assigns(:total_amounts), "Total amount must not be empty"
    assert_not_empty assigns(:item_lists), "Item lists must not be empty"
  end

  test "participant (non payer) can see Who owes you? details" do
    sign_in @user1
    get :who_owes_you, params: { event_id: @event.id }
    assert_response :success, "Response must be success"
    assert assigns(:event), "Event must be assigned"
    assert_empty assigns(:total_amounts), "Total amount must be empty"
    assert_empty assigns(:item_lists), "Item lists must be empty"
  end

  test "non participant cannot see Who owes you? details" do
    get :who_owes_you, params: { event_id: @event.id }
    assert_response :forbidden, "Response must be forbidden"
    assert_nil assigns(:total_amounts), "Total amounts must be emtpy"
    assert_nil assigns(:item_lists), "Item lists must be empty"
  end

  test "organizer can see you owe whom? details" do
    sign_in @organizer
    get :you_owe_whom, params: { event_id: @event.id }
    assert_response :success, "Response must be success"
    assert assigns(:event), "Event must be assigned"
    assert_not_empty assigns(:total_amounts), "Total amounts must not be empty"
    assert_not_empty assigns(:item_lists), "Item lists must not be empty"
  end

  test "participant (payer and beneficiary) can see you owe whom? details" do
    sign_in @user5
    get :you_owe_whom, params: { event_id: @event.id }
    assert_response :success, "Response must be success"
    assert assigns(:event), "Event must be assigned"
    assert_not_empty assigns(:total_amounts), "Total amounts must not be empty"
    assert_not_empty assigns(:item_lists), "Item lists must not be empty"
  end

  test "non participant cannot see you owe whom? details" do
    get :you_owe_whom, params: { event_id: @event.id }
    assert_response :forbidden, "Response must be forbidden"
    assert_nil assigns(:total_amounts), "Total amounts must be emtpy"
    assert_nil assigns(:item_lists), "Item lists must be empty"
  end

  # Test the views/pages
  
  test "index page with no events" do
    @event = nil
    get :index
    assert_select "title", "Your events"
    assert_select ".left-off-canvas-menu ul li a[href=?]", new_event_path, "Create new event"
    assert_select "p", "You don't have any events."
  end

  test "organizer's index page with events" do
    sign_in @organizer
    get :index
    
    # Test off-canvas menu
    assert_select ".left-off-canvas-menu ul li a[href=?]", new_event_path, "Create new event"
    assert_select "div.table-selector table.tablesaw[align=center]" 
    assert_select "div.table-selector table.tablesaw[data-tablesaw-mode=stack]"
    assert_select "div.table-selector table.tablesaw caption", "Your events"

    # Test top-bar menu
    assert_select ".title-area li.name  h1  a[href='#']", "Come Malaka!"
    assert_select ".top-bar-section ul.right li a[href=?]", new_event_path, "Create new event"

    # Test table 
    head = "div.table-selector table.tablesaw thead tr th"
    assert_select head, "Event"
    assert_select head, "Description"
    assert_select head, "Start date"
    assert_select head, "End date"
    assert_select head, "Event currency"
    assert_select head, "Organizer"
    assert_select head, "Participants*"
    assert_select "div.table-selector table.tablesaw tfoot tr[data-tablesaw-no-labels] td[colspan='7']", "* Hover or click over the text for details"
    assert_select "div.table-selector table.tablesaw tbody tr td a.dropdown[data-dropdown=action#{@event.id}]", "Randers"
    ul = "div.table-selector table.tablesaw tbody tr td ul#action#{@event.id}"
    assert_select ul + ".f-dropdown[data-dropdown-content]"
    assert_select ul + " li a[href='#{edit_event_path(@event)}']", 'Edit event'
    assert_select ul + " li a[href='#{event_path(@event)}'][data-confirm][data-method=delete]", 'Delete event'
    assert_select ul + " li a[href='#{event_path(@event)}']", 'View event details'
    assert_select ul + " li a[href='#{invite_to_event_path(@event)}']", 'Invite to event'
    assert_select ul + " li a[href='#{event_all_items_path(@event)}']", 'All event items'
    assert_select ul + " li a[href='#{event_items_path(@event)}']", 'Your event items'
    assert_select ul + " li a[href='#{expense_report_path(@event)}']", 'Expense Summary'
    tbody_td = "div.table-selector table.tablesaw tbody tr td"
    assert_select tbody_td, "Come Malaka event in Denmark"
    assert_select tbody_td, "02 Nov 2012"
    assert_select tbody_td, "04 Nov 2012"
    assert_select tbody_td + " span.has-tip[data-tooltip][title=?]", "Euro", {text: "EUR"}
    assert_select tbody_td + " span.has-tip[data-tooltip]:match('title', ?)", /.*Lasse.*/
    assert_select tbody_td + " span.has-tip[data-tooltip]:match('title', ?)", /.*Elyasin.*/
    assert_select tbody_td + " span.has-tip[data-tooltip]:match('title', ?)", /.*Theo.*/
    assert_select tbody_td + " span.has-tip[data-tooltip]:match('title', ?)", /.*Nuno.*/
    assert_select tbody_td + " span.has-tip[data-tooltip]:match('title', ?)", /.*Neal.*/
    assert_select tbody_td + " span.has-tip[data-tooltip]:match('title', ?)", /.*Juan.*/
    assert_select tbody_td + " span.has-tip[data-tooltip]", "6"
  end

  test "participant's index page with events" do
    sign_in @user1
    get :index

    # Test off-canvas menu
    assert_select ".left-off-canvas-menu ul li a[href=?]", new_event_path, "Create new event"

    # Test top-bar menu
    assert_select ".title-area li.name  h1  a[href='#']", "Come Malaka!"
    assert_select ".top-bar-section ul.right li a[href=?]", new_event_path, "Create new event"

    # Test table
    assert_select "div.table-selector table.tablesaw[align=center]" 
    assert_select "div.table-selector table.tablesaw[data-tablesaw-mode=stack]"
    assert_select "div.table-selector table.tablesaw caption", "Your events"
    head = "div.table-selector table.tablesaw thead tr th"
    assert_select head, "Event"
    assert_select head, "Description"
    assert_select head, "Start date"
    assert_select head, "End date"
    assert_select head, "Event currency"
    assert_select head, "Organizer"
    assert_select head, "Participants*"
    assert_select "div.table-selector table.tablesaw tfoot tr[data-tablesaw-no-labels] td[colspan='7']", "* Hover or click over the text for details"
    assert_select "div.table-selector table.tablesaw tbody tr td a.dropdown[data-dropdown=action#{@event.id}]", "Randers"
    ul = "div.table-selector table.tablesaw tbody tr td ul#action#{@event.id}"
    assert_select ul + ".f-dropdown[data-dropdown-content]"
    assert_select ul + " li a[href='#{edit_event_path(@event)}']", false
    assert_select ul + " li a[href='#{event_path(@event)}'][data-confirm][data-method=delete]", false
    assert_select ul + " li a[href='#{event_path(@event)}']", 'View event details'
    assert_select ul + " li a[href='#{invite_to_event_path(@event)}']", false
    assert_select ul + " li a[href='#{event_all_items_path(@event)}']", 'All event items'
    assert_select ul + " li a[href='#{event_items_path(@event)}']", 'Your event items'
    assert_select ul + " li a[href='#{expense_report_path(@event)}']", 'Expense Summary'
    tbody_td = "div.table-selector table.tablesaw tbody tr td"
    assert_select tbody_td, "Come Malaka event in Denmark"
    assert_select tbody_td, "02 Nov 2012"
    assert_select tbody_td, "04 Nov 2012"
    assert_select tbody_td + " span.has-tip[data-tooltip][title=?]", "Euro", {text: "EUR"}
    assert_select tbody_td + " span.has-tip[data-tooltip]:match('title', ?)", /.*Lasse.*/
    assert_select tbody_td + " span.has-tip[data-tooltip]:match('title', ?)", /.*Elyasin.*/
    assert_select tbody_td + " span.has-tip[data-tooltip]:match('title', ?)", /.*Theo.*/
    assert_select tbody_td + " span.has-tip[data-tooltip]:match('title', ?)", /.*Nuno.*/
    assert_select tbody_td + " span.has-tip[data-tooltip]:match('title', ?)", /.*Neal.*/
    assert_select tbody_td + " span.has-tip[data-tooltip]:match('title', ?)", /.*Juan.*/
    assert_select tbody_td + " span.has-tip[data-tooltip]", "6"
  end

  test "new event page" do
    get :new
    assert_select "title", "Create new event"
    
    # Test off-canvas menu
    assert_select ".left-off-canvas-menu ul li a[href=?]", events_path, "Back to events"
    assert_select ".left-off-canvas-menu ul li a[href=?]", new_event_path, "Create new event"
    
    # Test top-bar menu
    assert_select ".title-area li.name  h1  a[href='#']", "Come Malaka!"
    assert_select ".top-bar-section ul.right li a[href=?]", events_path, "Back to events"
    assert_select ".top-bar-section ul.right li a[href=?]", new_event_path, "Create new event"

    # Test form and Foundation Abide and Grid
    assert_select "form[data-abide=true][novalidate=novalidate]"
    assert_select "form div.row div.small-12.medium-8.large-6.columns.small-centered fieldset" do
      assert_select "legend", "Create new event"
      
      label = "div.field.small-12.medium-4.large-4.columns.end label"
      input = "div.small-12.medium-8.large-8.columns.end input"
      error = "div.small-12.medium-8.large-8.columns.end small.error"

      assert_select label, "Name"
      assert_select input + "#event_name[required=required]"
      assert_select error, "Please name the event."
      assert_select label, "Description"
      assert_select input + "#event_description[required=required]"
      assert_select error, "Please describe the event."
      assert_select label, "Start date"
      assert_select input + "#event_from_date[required=required]"
      assert_select input + "#event_from_date[size=?]", "10"
      assert_select error, "Please choose a start date for the event."
      assert_select label, "End date"
      assert_select input + "#event_end_date[required=required]"
      assert_select input + "#event_end_date[size=?]", "10" 
      assert_select error, "Please choose an end date for the event."
      assert_select label, "Event currency"
      assert_select "div.small-12.medium-8.large-8.columns.end select#event_event_currency" do
        assert_select "#event_event_currency[required=required]"
        assert_select "option[value=?]", "", {text: "Select event currency"}
        Money::Currency.all.each do |currency|
          assert_select "option[value=?]", currency.id.to_s, {text: currency.iso_code.to_s}
        end
      end
      assert_select error, "Please choose an event currency."
      assert_select label, "Organizer"
      assert_select "div.small-12.medium-8.large-8.columns.end select#event_organizer_id" do
        assert_select "option[value=?]", @non_participant_user.id.to_s
        assert_select "option[selected=selected]", "Javier Ductor"
      end
      assert_select "div.actions.small-12.medium-8.large-8.columns.end input[value=?]", "Create event"
    end
  end

  test "show event details page" do
    sign_in @organizer
    get :show, params: { id: @event.id }

    # Test off-canvas menu
    assert_select "title", "Details about Randers"
    assert_select ".left-off-canvas-menu ul li a[href=?]", event_all_items_path(assigns(:event)), "Back to all items"
    assert_select ".left-off-canvas-menu ul li a[href=?]", event_items_path(assigns(:event)), "Back to your items"
    assert_select ".left-off-canvas-menu ul li a[href=?]", events_path, "Back to events"
    assert_select ".left-off-canvas-menu ul li.has-submenu a[href='#']", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", new_event_path, "Create new event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li label", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", invite_to_event_path(assigns(:event)), "Invite to event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", event_path(assigns(:event)), "View event details"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", edit_event_path(assigns(:event)), "Edit event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?][data-method=delete]", event_path(assigns(:event)), "Delete event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu a[href='#']", "Expense Reports"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li label", "Expense Reports"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", expense_report_path(assigns(:event)), "Expense summary"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", who_owes_you_path(assigns(:event)), "Who owes you?"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", you_owe_whom_path(assigns(:event)), "You owe whom?"
    assert_select ".left-off-canvas-menu ul li.has-submenu a[href='#']", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", new_event_item_path(assigns(:event)), "Create new item"

    # Test top-bar menu
    assert_select ".title-area li.name  h1  a[href='#']", "Come Malaka!"
    assert_select ".top-bar-section li a[href=?]", new_event_path, "Create new event"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Back to ..."
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", events_path, "... events"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_all_items_path(assigns(:event)), "... all items (#{assigns(:event).name})"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_items_path(assigns(:event)), "... your items (#{assigns(:event).name})"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Randers event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", invite_to_event_path(assigns(:event)), "Invite to event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.active a[href=?]", event_path(assigns(:event)), "View event details"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", edit_event_path(assigns(:event)), "Edit event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?][data-method=delete]", event_path(assigns(:event)), "Delete event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown a[href='#']", "Expense Reports"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", expense_report_path(assigns(:event)), "Expense summary"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", who_owes_you_path(assigns(:event)), "Who owes you?"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", you_owe_whom_path(assigns(:event)), "You owe whom?"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Randers items"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", new_event_item_path(assigns(:event)), "Create new item"

    # Test Grid and Form
    assert_select "form div.row div.small-12.medium-8.large-6.columns.small-centered fieldset" do
      assert_select "[disabled]"
      assert_select "legend", "View event details"
      assert_select "div.row", 7
      
      label = "div.row div.field.small-12.medium-4.large-4.columns.end label"
      input = "div.row div.small-12.medium-8.large-8.columns.end input"

      assert_select label, "Name" 
      assert_select input + "#event_name[value=Randers]"
      assert_select label, "Description"
      assert_select input + "#event_description[value=?]", "Come Malaka event in Denmark"
      assert_select label, "Start date"
      assert_select input + "#event_from_date[value=?]", "2012-11-02"
      assert_select label, "End date"
      assert_select input + "#event_end_date[value=?]", "2012-11-04"
      assert_select label, "Event currency"
      assert_select input + "#event_event_currency[value=EUR]"
      assert_select label, "Organizer"
      assert_select input + "#dummy[value=?]", "Lasse Lund"
      assert_select label, "Participants"
      assigns(:event).users.each do |user|
        assert_select "div.row div.small-12.medium-8.large-8.columns.end label[for=?]", "event_user_ids_" + user.id.to_s, {text: user.name}
        assert_select "div.row div.small-12.medium-8.large-8.columns.end label input#event_user_ids_" + user.id.to_s + "[checked=checked][value=?]", user.id.to_s 
      end
    end
  end

#When items are posted the event currency cannot be modified
test "edit event page (with posted items)" do
    sign_in @organizer
    get :edit, params: { id: @event.id }
    assert_select "title", "Edit Randers event"

    # Test off-canvas menu
    assert_select ".left-off-canvas-menu ul li a[href=?]", event_all_items_path(assigns(:event)), "Back to all items"
    assert_select ".left-off-canvas-menu ul li a[href=?]", event_items_path(assigns(:event)), "Back to your items"
    assert_select ".left-off-canvas-menu ul li a[href=?]", events_path, "Back to events"
    assert_select ".left-off-canvas-menu ul li.has-submenu a[href='#']", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", new_event_path, "Create new event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li label", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", invite_to_event_path(assigns(:event)), "Invite to event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", event_path(assigns(:event)), "View event details"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", edit_event_path(assigns(:event)), "Edit event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?][data-method=delete]", event_path(assigns(:event)), "Delete event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu a[href='#']", "Expense Reports"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li label", "Expense Reports"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", expense_report_path(assigns(:event)), "Expense summary"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", who_owes_you_path(assigns(:event)), "Who owes you?"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", you_owe_whom_path(assigns(:event)), "You owe whom?"
    assert_select ".left-off-canvas-menu ul li.has-submenu a[href='#']", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", new_event_item_path(assigns(:event)), "Create new item"

    # Test top-bar menu
    assert_select ".title-area li.name  h1  a[href='#']", "Come Malaka!"
    assert_select ".top-bar-section li a[href=?]", new_event_path, "Create new event"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Back to ..."
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", events_path, "... events"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_all_items_path(assigns(:event)), "... all items (#{assigns(:event).name})"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_items_path(assigns(:event)), "... your items (#{assigns(:event).name})"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Randers event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", invite_to_event_path(assigns(:event)), "Invite to event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_path(assigns(:event)), "View event details"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.active a[href=?]", edit_event_path(assigns(:event)), "Edit event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?][data-method=delete]", event_path(assigns(:event)), "Delete event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown a[href='#']", "Expense Reports"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", expense_report_path(assigns(:event)), "Expense summary"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", who_owes_you_path(assigns(:event)), "Who owes you?"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", you_owe_whom_path(assigns(:event)), "You owe whom?"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Randers items"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", new_event_item_path(assigns(:event)), "Create new item"

    #Test form and Foundation Abide and Grid
    assert_select "form[data-abide=true]"
    assert_select "form[novalidate=novalidate]"
    assert_select "form div.row div.small-12.medium-8.large-6.columns.small-centered fieldset" do
      assert_select "legend", "Edit event"
      
      label = "div.field.small-12.medium-4.large-4.columns.end label"
      input = "div.small-12.medium-8.large-8.columns.end input"
      error = "div.small-12.medium-8.large-8.columns.end small.error"

      assert_select label, "Name"
      assert_select input + "#event_name[required=required]"
      assert_select error, "Please name the event."
      assert_select label, "Description"
      assert_select input + "#event_description[required=required]"
      assert_select error, "Please describe the event."
      assert_select label, "Start date"
      assert_select input + "#event_from_date[required=required]"
      assert_select input + "#event_from_date[size=?]", "10"
      assert_select error, "Please choose a start date for the event."
      assert_select label, "End date"
      assert_select input + "#event_end_date[required=required]"
      assert_select input + "#event_end_date[size=?]", "10"
      assert_select error, "Please choose an end date for the event."
      assert_select label, "Event currency"
      assert_select input + "#event_event_currency[value=?][disabled=disabled]", "EUR"
      assert_select "div.actions.small-12.medium-8.large-8.columns.end input[value=?]", "Save event"
    end
  end

  #when there are no posted items the event currency can be modified
test "edit event page (without posted items)" do
    sign_in @organizer
    @event.items = nil
    get :edit, params: { id: @event.id }

    # Test off-canvas menu
    assert_select "title", "Edit Randers event"
    assert_select ".left-off-canvas-menu ul li a[href=?]", event_all_items_path(assigns(:event)), "Back to all items"
    assert_select ".left-off-canvas-menu ul li a[href=?]", event_items_path(assigns(:event)), "Back to your items"
    assert_select ".left-off-canvas-menu ul li a[href=?]", events_path, "Back to events"
    assert_select ".left-off-canvas-menu ul li.has-submenu a[href='#']", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", new_event_path, "Create new event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li label", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", invite_to_event_path(assigns(:event)), "Invite to event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", event_path(assigns(:event)), "View event details"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", edit_event_path(assigns(:event)), "Edit event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?][data-method=delete]", event_path(assigns(:event)), "Delete event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu a[href='#']", "Expense Reports"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li label", "Expense Reports"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", expense_report_path(assigns(:event)), "Expense summary"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", who_owes_you_path(assigns(:event)), "Who owes you?"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", you_owe_whom_path(assigns(:event)), "You owe whom?"
    assert_select ".left-off-canvas-menu ul li.has-submenu a[href='#']", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", new_event_item_path(assigns(:event)), "Create new item"

    # Test top-bar menu
    assert_select ".title-area li.name  h1  a[href='#']", "Come Malaka!"
    assert_select ".top-bar-section li a[href=?]", new_event_path, "Create new event"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Back to ..."
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", events_path, "... events"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_all_items_path(assigns(:event)), "... all items (#{assigns(:event).name})"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_items_path(assigns(:event)), "... your items (#{assigns(:event).name})"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Randers event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", invite_to_event_path(assigns(:event)), "Invite to event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_path(assigns(:event)), "View event details"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.active a[href=?]", edit_event_path(assigns(:event)), "Edit event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?][data-method=delete]", event_path(assigns(:event)), "Delete event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown a[href='#']", "Expense Reports"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", expense_report_path(assigns(:event)), "Expense summary"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", who_owes_you_path(assigns(:event)), "Who owes you?"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", you_owe_whom_path(assigns(:event)), "You owe whom?"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Randers items"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", new_event_item_path(assigns(:event)), "Create new item"

    # Test form and Foundation Abide and Grid
    assert_select "form[data-abide=true]"
    assert_select "form[novalidate=novalidate]"
    assert_select "form div.row div.small-12.medium-8.large-6.columns.small-centered fieldset" do
      assert_select "legend", "Edit event"
      
      label = "div.field.small-12.medium-4.large-4.columns.end label"
      input = "div.small-12.medium-8.large-8.columns.end input"
      error = "div.small-12.medium-8.large-8.columns.end small.error"

      assert_select label, "Name"
      assert_select input + "#event_name[required=required]"
      assert_select error, "Please name the event."
      assert_select label, "Description"
      assert_select input + "#event_description[required=required]"
      assert_select error, "Please describe the event."
      assert_select label, "Start date"
      assert_select input + "#event_from_date[required=required]"
      assert_select input + "#event_from_date[size=?]", "10"
      assert_select error, "Please choose a start date for the event."
      assert_select label, "End date"
      assert_select input + "#event_end_date[required=required]"
      assert_select input + "#event_end_date[size=?]", "10"
      assert_select error, "Please choose an end date for the event."
      assert_select label, "Event currency"
      assert_select "div.small-12.medium-8.large-8.columns.end select#event_event_currency" do
        Money::Currency.all.each do |currency|
          assert_select "option[value=?]", currency.id.to_s, {text: currency.iso_code.to_s}
        end
      end
      assert_select "div.actions.small-12.medium-8.large-8.columns.end input[value=?]", "Save event"
    end
  end

  test "expense report page" do
    sign_in @organizer
    get :expense_report, params: { event_id: @event.id }

    # Test off-canvas menu
    assert_select "title", "Expense summary for Randers event"
    assert_select ".left-off-canvas-menu ul li a[href=?]", event_all_items_path(assigns(:event)), "Back to all items"
    assert_select ".left-off-canvas-menu ul li a[href=?]", event_items_path(assigns(:event)), "Back to your items"
    assert_select ".left-off-canvas-menu ul li a[href=?]", events_path, "Back to events"
    assert_select ".left-off-canvas-menu ul li.has-submenu a[href='#']", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", new_event_path, "Create new event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li label", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", invite_to_event_path(assigns(:event)), "Invite to event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", event_path(assigns(:event)), "View event details"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", edit_event_path(assigns(:event)), "Edit event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?][data-method=delete]", event_path(assigns(:event)), "Delete event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu a[href='#']", "Expense Reports"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li label", "Expense Reports"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", expense_report_path(assigns(:event)), "Expense summary"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", who_owes_you_path(assigns(:event)), "Who owes you?"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", you_owe_whom_path(assigns(:event)), "You owe whom?"
    assert_select ".left-off-canvas-menu ul li.has-submenu a[href='#']", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", new_event_item_path(assigns(:event)), "Create new item"

    # Test top-bar menu
    assert_select ".title-area li.name  h1  a[href='#']", "Come Malaka!"
    assert_select ".top-bar-section li a[href=?]", new_event_path, "Create new event"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Back to ..."
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", events_path, "... events"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_all_items_path(assigns(:event)), "... all items (#{assigns(:event).name})"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_items_path(assigns(:event)), "... your items (#{assigns(:event).name})"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Randers event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", invite_to_event_path(assigns(:event)), "Invite to event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_path(assigns(:event)), "View event details"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", edit_event_path(assigns(:event)), "Edit event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?][data-method=delete]", event_path(assigns(:event)), "Delete event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown a[href='#']", "Expense Reports"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li.active a[href=?]", expense_report_path(assigns(:event)), "Expense summary"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", who_owes_you_path(assigns(:event)), "Who owes you?"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", you_owe_whom_path(assigns(:event)), "You owe whom?"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Randers items"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", new_event_item_path(assigns(:event)), "Create new item"

    #Test table and Foundation Grid
    table = "div.row div.small-12.columns.small-centered.table-selector table.tablesaw"
    assert_select table + "[role=grid][data-tablesaw-mode=stack]" 
    assert_select table + " caption", /Expense Summary\*/
    assert_select table + " caption span.has-tip[data-tooltip][title=?]", "Euro", {text: "(base currency is EUR)"}
    head = table + " thead tr th"
    assert_select head, "Participant"
    assert_select head, "Total Paid"
    assert_select head, "Total Benefited"
    assert_select head, "Balance"
    assert_select table + " tfoot tr[data-tablesaw-no-labels] td[colspan='4']", "*Amounts are rounded for display"
    body = table + " tbody tr td"
    @event.users.each do |participant|
      assert_select body, participant.short_name
      assert_select body, money_format(@event.total_expenses_amount_for(participant), @event.event_currency)
      assert_select body, money_format(@event.total_benefited_amount_for(participant), @event.event_currency)
      assert_select body, money_format(@event.balance_for(participant), @event.event_currency)
    end 
  end

  test "event's all items page (with items)" do
    sign_in @organizer
    get :event_all_items, params: { event_id: @event.id }
    assert_select "title", "All items of Randers event"

    # Test off-canvas menu
    assert_select ".left-off-canvas-menu ul li a[href=?]", event_all_items_path(assigns(:event)), "Back to all items"
    assert_select ".left-off-canvas-menu ul li a[href=?]", event_items_path(assigns(:event)), "Back to your items"
    assert_select ".left-off-canvas-menu ul li a[href=?]", events_path, "Back to events"
    assert_select ".left-off-canvas-menu ul li.has-submenu a[href='#']", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", new_event_path, "Create new event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li label", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", invite_to_event_path(assigns(:event)), "Invite to event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", event_path(assigns(:event)), "View event details"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", edit_event_path(assigns(:event)), "Edit event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?][data-method=delete]", event_path(assigns(:event)), "Delete event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu a[href='#']", "Expense Reports"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li label", "Expense Reports"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", expense_report_path(assigns(:event)), "Expense summary"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", who_owes_you_path(assigns(:event)), "Who owes you?"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", you_owe_whom_path(assigns(:event)), "You owe whom?"
    assert_select ".left-off-canvas-menu ul li.has-submenu a[href='#']", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", new_event_item_path(assigns(:event)), "Create new item"

    # Test top-bar menu
    assert_select ".title-area li.name  h1  a[href='#']", "Come Malaka!"
    assert_select ".top-bar-section li a[href=?]", new_event_path, "Create new event"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Back to ..."
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", events_path, "... events"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.active a[href=?]", event_all_items_path(assigns(:event)), "... all items (#{assigns(:event).name})"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_items_path(assigns(:event)), "... your items (#{assigns(:event).name})"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Randers event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", invite_to_event_path(assigns(:event)), "Invite to event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_path(assigns(:event)), "View event details"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", edit_event_path(assigns(:event)), "Edit event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?][data-method=delete]", event_path(assigns(:event)), "Delete event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown a[href='#']", "Expense Reports"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", expense_report_path(assigns(:event)), "Expense summary"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", who_owes_you_path(assigns(:event)), "Who owes you?"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", you_owe_whom_path(assigns(:event)), "You owe whom?"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Randers items"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", new_event_item_path(assigns(:event)), "Create new item"

    table = "div.table-selector table.tablesaw[role=grid][data-tablesaw-mode=stack]"
    assert_select table + " caption", "All items of Randers event"
    head = table + " thead tr th"
    assert_select head, "Name"
    assert_select head, "Date"
    assert_select head, "Description"
    assert_select head, "Base amount*"
    assert_select head, "Exchange rate"
    assert_select head, "Foreign amount*"
    assert_select head, "Payer"
    assert_select head, "Beneficiaries**"
    assert_select head, "Cost per beneficiary"
    foot = table + " tfoot tr[data-tablesaw-no-labels] td[colspan='9']"
    assert_select foot, /^\* Amounts are rounded for display\n\n\*\* Hover or click over the text for details$/
    body = table + " tbody tr td"
    assigns(:items).each do |item|
      assert_select body + " a.dropdown[data-dropdown=?]", "action" + item.id.to_s, {text: item.name}
      li = body + " ul.f-dropdown#action#{item.id.to_s}[data-dropdown-content] li"
      assert_select li + " a[href=?]", item_path(item), "View item details"
      if item.payer == @organizer then
        assert_select li + " a[href=?]", edit_item_path(item), "Edit item"
        assert_select li + " a[href=?][data-confirm][data-method=delete]", item_path(item), "Delete item"
      end
      assert_select body, item.value_date.strftime('%d %b %Y')
      assert_select body, item.description
      assert_select body + " span.has-tip[data-tooltip][title=?]", "Euro", money_format(item.base_amount, item.base_currency)
      assert_select body, item.exchange_rate.to_s
      assert_select body + " span.has-tip[data-tooltip][title=?]", "Danish Krone", money_format(item.foreign_amount, item.foreign_currency)
      assert_select body, item.payer.short_name
      assert_select body + " span.has-tip[data-tooltip]:match('title', ?)", /.*Lasse.*/
      assert_select body + " span.has-tip[data-tooltip]:match('title', ?)", /.*Elyasin.*/
      assert_select body + " span.has-tip[data-tooltip]:match('title', ?)", /.*Theo.*/
      assert_select body + " span.has-tip[data-tooltip]:match('title', ?)", /.*Nuno.*/
      assert_select body + " span.has-tip[data-tooltip]:match('title', ?)", /.*Neal.*/
      assert_select body + " span.has-tip[data-tooltip]:match('title', ?)", /.*Juan.*/
      assert_select body + " span.has-tip[data-tooltip]", "6"
      assert_select body, money_format(item.cost_per_beneficiary, item.base_currency)
    end
  end

  test "event's all items page (without items)" do
    @event.items = []
    sign_in @organizer
    get :event_all_items, params: { event_id: @event.id }
    assert_select "title", "All items of Randers event"

    # Test off-canvas menu
    assert_select ".left-off-canvas-menu ul li a[href=?]", event_all_items_path(assigns(:event)), "Back to all items"
    assert_select ".left-off-canvas-menu ul li a[href=?]", event_items_path(assigns(:event)), "Back to your items"
    assert_select ".left-off-canvas-menu ul li a[href=?]", events_path, "Back to events"
    assert_select ".left-off-canvas-menu ul li.has-submenu a[href='#']", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", new_event_path, "Create new event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li label", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", invite_to_event_path(assigns(:event)), "Invite to event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", event_path(assigns(:event)), "View event details"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", edit_event_path(assigns(:event)), "Edit event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?][data-method=delete]", event_path(assigns(:event)), "Delete event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu a[href='#']", "Expense Reports"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li label", "Expense Reports"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", expense_report_path(assigns(:event)), "Expense summary"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", who_owes_you_path(assigns(:event)), "Who owes you?"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", you_owe_whom_path(assigns(:event)), "You owe whom?"
    assert_select ".left-off-canvas-menu ul li.has-submenu a[href='#']", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", new_event_item_path(assigns(:event)), "Create new item"

    # Test top-bar menu
    assert_select ".title-area li.name  h1  a[href='#']", "Come Malaka!"
    assert_select ".top-bar-section li a[href=?]", new_event_path, "Create new event"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Back to ..."
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", events_path, "... events"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.active a[href=?]", event_all_items_path(assigns(:event)), "... all items (#{assigns(:event).name})"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_items_path(assigns(:event)), "... your items (#{assigns(:event).name})"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Randers event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", invite_to_event_path(assigns(:event)), "Invite to event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_path(assigns(:event)), "View event details"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", edit_event_path(assigns(:event)), "Edit event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?][data-method=delete]", event_path(assigns(:event)), "Delete event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown a[href='#']", "Expense Reports"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", expense_report_path(assigns(:event)), "Expense summary"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", who_owes_you_path(assigns(:event)), "Who owes you?"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", you_owe_whom_path(assigns(:event)), "You owe whom?"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Randers items"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", new_event_item_path(assigns(:event)), "Create new item"


    assert_select "p", "You don't have any items."
  end

  test "who owes you page" do
    sign_in @organizer
    get :who_owes_you, params: { event_id: @event.id }
    assert_select "title", "Who owes you?"

    # Test off-canvas menu
    assert_select ".left-off-canvas-menu ul li a[href=?]", event_all_items_path(assigns(:event)), "Back to all items"
    assert_select ".left-off-canvas-menu ul li a[href=?]", event_items_path(assigns(:event)), "Back to your items"
    assert_select ".left-off-canvas-menu ul li a[href=?]", events_path, "Back to events"
    assert_select ".left-off-canvas-menu ul li.has-submenu a[href='#']", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", new_event_path, "Create new event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li label", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", invite_to_event_path(assigns(:event)), "Invite to event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", event_path(assigns(:event)), "View event details"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", edit_event_path(assigns(:event)), "Edit event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?][data-method=delete]", event_path(assigns(:event)), "Delete event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu a[href='#']", "Expense Reports"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li label", "Expense Reports"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", expense_report_path(assigns(:event)), "Expense summary"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", who_owes_you_path(assigns(:event)), "Who owes you?"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", you_owe_whom_path(assigns(:event)), "You owe whom?"
    assert_select ".left-off-canvas-menu ul li.has-submenu a[href='#']", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", new_event_item_path(assigns(:event)), "Create new item"

    # Test top-bar menu
    assert_select ".title-area li.name  h1  a[href='#']", "Come Malaka!"
    assert_select ".top-bar-section li a[href=?]", new_event_path, "Create new event"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Back to ..."
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", events_path, "... events"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_all_items_path(assigns(:event)), "... all items (#{assigns(:event).name})"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_items_path(assigns(:event)), "... your items (#{assigns(:event).name})"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Randers event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", invite_to_event_path(assigns(:event)), "Invite to event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_path(assigns(:event)), "View event details"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", edit_event_path(assigns(:event)), "Edit event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?][data-method=delete]", event_path(assigns(:event)), "Delete event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown a[href='#']", "Expense Reports"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", expense_report_path(assigns(:event)), "Expense summary"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li.active a[href=?]", who_owes_you_path(assigns(:event)), "Who owes you?"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", you_owe_whom_path(assigns(:event)), "You owe whom?"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Randers items"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", new_event_item_path(assigns(:event)), "Create new item"

    ul_header = "ul[style='list-style-type:none'] li u"
    ul_line = "ul[style='list-style-type:none'] ul li"

    assert_select ul_header, "Elyasin owes you €124.00 in total"
    assert_select ul_line, "Elyasin owes you €40.22 on the 02 Nov 2012 for item Food (Food)"
    assert_select ul_line, "Elyasin owes you €11.17 on the 02 Nov 2012 for item Gas (Gas)"
    assert_select ul_line, "Elyasin owes you €11.17 on the 02 Nov 2012 for item Drinks (Drinks)"
    assert_select ul_line, "Elyasin owes you €36.86 on the 02 Nov 2012 for item Night out (Night out & Misc)"
    assert_select ul_line, "Elyasin owes you €24.58 on the 03 Nov 2012 for item Night out (Night out & Misc)"
    assert_select ul_header, "Juan owes you €124.00 in total"
    assert_select ul_line, "Juan owes you €40.22 on the 02 Nov 2012 for item Food (Food)"
    assert_select ul_line, "Juan owes you €11.17 on the 02 Nov 2012 for item Gas (Gas)"
    assert_select ul_line, "Juan owes you €11.17 on the 02 Nov 2012 for item Drinks (Drinks)"
    assert_select ul_line, "Juan owes you €36.86 on the 02 Nov 2012 for item Night out (Night out & Misc)"
    assert_select ul_line, "Juan owes you €24.58 on the 03 Nov 2012 for item Night out (Night out & Misc)"
    assert_select ul_header, "Neal owes you €87.14 in total"
    assert_select ul_line, "Neal owes you €40.22 on the 02 Nov 2012 for item Food (Food)"
    assert_select ul_line, "Neal owes you €11.17 on the 02 Nov 2012 for item Gas (Gas)"
    assert_select ul_line, "Neal owes you €11.17 on the 02 Nov 2012 for item Drinks (Drinks)"
    assert_select ul_line, "Neal owes you €24.58 on the 03 Nov 2012 for item Night out (Night out & Misc)"    
    assert_select ul_header, "Nuno owes you €124.00 in total"
    assert_select ul_line, "Nuno owes you €40.22 on the 02 Nov 2012 for item Food (Food)"
    assert_select ul_line, "Nuno owes you €11.17 on the 02 Nov 2012 for item Gas (Gas)"
    assert_select ul_line, "Nuno owes you €11.17 on the 02 Nov 2012 for item Drinks (Drinks)"
    assert_select ul_line, "Nuno owes you €36.86 on the 02 Nov 2012 for item Night out (Night out & Misc)"
    assert_select ul_line, "Nuno owes you €24.58 on the 03 Nov 2012 for item Night out (Night out & Misc)"
    assert_select ul_header, "Theo owes you €87.14 in total"
    assert_select ul_line, "Theo owes you €40.22 on the 02 Nov 2012 for item Food (Food)"
    assert_select ul_line, "Theo owes you €11.17 on the 02 Nov 2012 for item Gas (Gas)"
    assert_select ul_line, "Theo owes you €11.17 on the 02 Nov 2012 for item Drinks (Drinks)"
    assert_select ul_line, "Theo owes you €24.58 on the 03 Nov 2012 for item Night out (Night out & Misc)"
  end


  test "you owe whom page" do
    sign_in @organizer
    get :you_owe_whom, params: { event_id: @event.id }
    assert_select "title", "You owe whom?"

    # Test off-canvas menu
    assert_select ".left-off-canvas-menu ul li a[href=?]", event_all_items_path(assigns(:event)), "Back to all items"
    assert_select ".left-off-canvas-menu ul li a[href=?]", event_items_path(assigns(:event)), "Back to your items"
    assert_select ".left-off-canvas-menu ul li a[href=?]", events_path, "Back to events"
    assert_select ".left-off-canvas-menu ul li.has-submenu a[href='#']", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", new_event_path, "Create new event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li label", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", invite_to_event_path(assigns(:event)), "Invite to event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", event_path(assigns(:event)), "View event details"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", edit_event_path(assigns(:event)), "Edit event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?][data-method=delete]", event_path(assigns(:event)), "Delete event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu a[href='#']", "Expense Reports"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li label", "Expense Reports"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", expense_report_path(assigns(:event)), "Expense summary"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", who_owes_you_path(assigns(:event)), "Who owes you?"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", you_owe_whom_path(assigns(:event)), "You owe whom?"
    assert_select ".left-off-canvas-menu ul li.has-submenu a[href='#']", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", new_event_item_path(assigns(:event)), "Create new item"

    # Test top-bar menu
    assert_select ".title-area li.name  h1  a[href='#']", "Come Malaka!"
    assert_select ".top-bar-section li a[href=?]", new_event_path, "Create new event"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Back to ..."
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", events_path, "... events"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_all_items_path(assigns(:event)), "... all items (#{assigns(:event).name})"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_items_path(assigns(:event)), "... your items (#{assigns(:event).name})"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Randers event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", invite_to_event_path(assigns(:event)), "Invite to event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_path(assigns(:event)), "View event details"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", edit_event_path(assigns(:event)), "Edit event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?][data-method=delete]", event_path(assigns(:event)), "Delete event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown a[href='#']", "Expense Reports"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", expense_report_path(assigns(:event)), "Expense summary"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", who_owes_you_path(assigns(:event)), "Who owes you?"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li.active a[href=?]", you_owe_whom_path(assigns(:event)), "You owe whom?"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Randers items"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", new_event_item_path(assigns(:event)), "Create new item"


    ul_header = "ul[style='list-style-type:none'] li u"
    ul_line = "ul[style='list-style-type:none'] ul li"

    assert_select ul_header, "You owe Juan €1.79 in total"
    assert_select ul_line, "You owe Juan €1.79 on the 03 Nov 2012 for item Taxi (Taxi)"
  end

end
