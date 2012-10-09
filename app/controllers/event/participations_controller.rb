class Event::ParticipationsController < CrudController
  self.nesting = Event
  
  decorates :event, :participation, :participations
  
  # load event before authorization
  prepend_before_filter :parent, :set_group
  before_render_form :load_priorities
  
  
  def new
    assign_attributes
    entry.init_answers
    respond_with(entry)
  end
  
=begin
  def create
    super(location: event_participations_path(entry.event_id))
  end
  
  def update
    super(location: event_participation_path(entry.event_id, entry.id))
  end
  
  def destroy
    super(location: event_participations_path(entry.event_id))
  end
=end
    
    
  def authorize!(action, *args)
    if [:index, :show].include?(action)
      super(:index_participations, parent)
    else
      super
    end
  end
  
  private
    
  def list_entries(action = :index)
    parent.participations.
           where(event_participations: {active: true}).
           includes(:person, :roles).
           order_by_role(parent.class).
           merge(Person.order_by_name)
           # TODO preload_public_accounts
  end
  
  
  # new and create are only invoked by people who wish to
  # apply for an event themselves. A participation for somebody
  # else is created through event roles. 
  def build_entry
    participation = parent.participations.new
    participation.person = current_user
    if parent.supports_applications
      appl = participation.build_application
      appl.priority_1 = parent
    end
    participation
  end
  
  def assign_attributes
    super
    # Set these attrs again as a new application instance might have been created by the mass assignment.
    entry.application.priority_1 ||= parent if entry.application
  end
  
  def set_group
    @group = parent.group
  end
    
  def load_priorities
    if entry.application
      # TODO: restrict to visible courses
      @priority_2s = @priority_3s = Event::Course.where(kind_id: parent.kind_id)
    end
  end
  
  # A label for the current entry, including the model name, used for flash
  def full_entry_label
    "#{models_label(false)} #{Event::ParticipationDecorator.decorate(entry).flash_info}".html_safe
  end
  
  class << self
    def model_class
      Event::Participation
    end
  end
end