# frozen_string_literal: true

# Contains all the fields available in the entire application.
# @todo Only a placeholder module until all the field definitions are added.
module MetadataApplicationProfile::BaseMAP
  extend ActiveSupport::Concern

  included do
    # @todo Example property only; can be removed or renamed
    MetadataApplicationProfile::Field.all.each do |field|
      attribute field.label.parameterize.underscore.to_sym, Valkyrie::Types::Set
    end
  end
end