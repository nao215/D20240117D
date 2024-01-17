json.status 200
json.note do
  json.id @note.id
  json.title @note.title
  json.content @note.content
  json.updated_at @note.updated_at.iso8601
end
