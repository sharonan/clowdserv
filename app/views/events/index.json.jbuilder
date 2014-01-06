json.array!(@events) do |event|
  json.extract! event, :title, :status
  json.url event_url(event, format: :json)
end
