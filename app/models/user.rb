class User < ApplicationRecord
  has_many :notes, dependent: :destroy

  # validations

  validates :username, uniqueness: true

  validates :username, length: { in: 0..0 }, if: :username?

  # end for validations

  class << self
  end
end
