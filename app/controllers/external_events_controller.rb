# frozen_string_literal: true

class ExternalEventsController < CmsBaseController
  layout "organiser"

  def edit
    @event = Event.find_by!(organiser_token: params[:id])
    @form = OrganiserEditEventForm.from_event(@event)
  end

  def update
    @event = Event.find_by!(organiser_token: params[:id])

    @form = OrganiserEditEventForm.new(event_params.merge(frequency: @event.frequency))
    if @form.valid?
      EventUpdater.new(@event).update!(@form.to_h)
      flash[:success] = t("flash.success", model: "Event", action: "updated")
      redirect_to edit_external_event_path(@event.organiser_token)
    else
      render action: "edit"
    end
  end

  private

  def authenticate
    organiser_token = params[:id]
    Event.find_by!(organiser_token:)

    @current_user = OrganiserUser.new(organiser_token)
  end

  def event_params
    params.require(:event).permit(
      %i[
        venue_id
        dates
        cancellations
        last_date
      ]
    )
  end
end
