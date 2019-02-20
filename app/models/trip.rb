class Trip < ApplicationRecord
  belongs_to :user
  belongs_to :itinerary
  has_many :user_trips
  has_many :messages, dependent: :destroy
  validates :start_date, presence: true
  validates :end_date, presence: true
  # validates :title, presence: true
end
