class User < ApplicationRecord
    has_many :messages
    has_many :groups, through: :group_users
    has_many :group_users
end
