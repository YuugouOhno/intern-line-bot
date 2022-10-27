class Message < ApplicationRecord
  belongs_to :group
  belongs_to :user
  attribute :posted_at, :datetime, default: -> {Time.now}
end
