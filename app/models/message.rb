class Message < ApplicationRecord
  belongs_to :group
  attribute :posted_at, :datetime, default: -> {Time.now}
end
