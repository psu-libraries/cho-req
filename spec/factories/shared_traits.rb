# frozen_string_literal: true

FactoryBot.define do
  trait :restricted_to_penn_state do
    read_groups { [Repository::AccessLevel.psu] }
  end
end
