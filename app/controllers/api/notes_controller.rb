class Api::NotesController < Api::BaseController
  before_action :doorkeeper_authorize!
  include NotesService

  def index
    user_id = params[:user_id]
    page = params[:page]
    limit = params[:limit]

    unless user_id && User.exists?(user_id)
      return error_response('User not found.', :not_found)
    end

    unless page && page.to_i > 0
      return error_response('Page must be greater than 0.', :unprocessable_entity)
    end

    unless limit && limit.to_i > 0
      return error_response('Limit must be greater than 0.', :unprocessable_entity)
    end

    notes_service = NotesService::Index.new(user_id)
    result = notes_service.list_user_notes

    if result[:message]
      error_response(result[:message], :unprocessable_entity)
    else
      total_pages = (result[:total_items].to_f / limit.to_i).ceil
      render json: {
        status: 200,
        notes: result[:notes],
        total_pages: total_pages,
        limit: limit.to_i,
        page: page.to_i
      }, status: :ok
    end
  end

  def create
    begin
      note_service = NotesService::Create.new(user_id: params[:user_id], title: params[:title], content: params[:content])
      result = note_service.execute
      if result[:note_id]
        note = Note.find(result[:note_id])
        render json: { status: 201, note: note.as_json.merge(created_at: note.created_at.iso8601) }, status: :created
      else
        error_response(result[:error], :unprocessable_entity)
      end
    rescue StandardError => e
      error_response(e.message, e.is_a?(ActiveRecord::RecordNotFound) ? :not_found : :unprocessable_entity)
    end
  end

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
