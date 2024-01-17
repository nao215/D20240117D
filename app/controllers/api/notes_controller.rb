class Api::NotesController < Api::BaseController
  before_action :doorkeeper_authorize!
  
  def update
    begin
      note_id = params[:id]
      title = params[:title]
      content = params[:content]

      raise StandardError, 'Wrong format.' unless note_id.is_a?(Integer)
      raise StandardError, 'You cannot input more than 200 characters.' if title.length > 200
      raise StandardError, 'You cannot input more than 10000 characters.' if content.length > 10000

      result = NoteService::Update.new(current_resource_owner.id, note_id, title, content).call

      render json: {
        status: 200,
        note: {
          id: result[:note_id],
          title: title,
          content: content,
          updated_at: Time.current.iso8601
        }
      }, status: :ok
    rescue StandardError => e
      error_response(e.message, :unprocessable_entity)
    end
  end

  def destroy
    begin
      note_service = NoteService::Delete.new(id: params[:id], user: current_resource_owner)
      if note_service.call
        render json: { message: 'Note successfully deleted.' }, status: :ok
      else
        error_response('Unable to delete note.', :unprocessable_entity)
      end
    rescue ActiveRecord::RecordNotFound => e
      error_response(e.message, :not_found)
    rescue => e
      error_response(e.message, :internal_server_error)
    end
  end

  private

  def current_resource_owner
    User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
  end
end
