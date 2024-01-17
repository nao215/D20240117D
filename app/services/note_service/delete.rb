
# frozen_string_literal: true

module NoteService
  class Delete < BaseService
    attr_reader :note_id, :user

    def initialize(note_id:, user:)
      @note_id = note_id
      @user = user
    end

    def call
      note = Note.find_by(id: note_id)
      raise ActiveRecord::RecordNotFound, 'Note not found' unless note

      authorize_user!(note)

      if note.destroy
        { status: 200, message: 'Note successfully deleted.' }
      else
        raise StandardError, 'Failed to delete the note.'
      end
    end

    private

    def authorize_user!(note)
      policy = NotePolicy.new(user, note)
      raise Pundit::NotAuthorizedError unless policy.destroy?
    end
  end
end
