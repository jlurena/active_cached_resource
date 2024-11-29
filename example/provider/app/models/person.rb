class Person < ApplicationRecord
  has_many :addresses, dependent: :destroy
  has_one :company, dependent: :destroy

  accepts_nested_attributes_for :addresses, :company
end
