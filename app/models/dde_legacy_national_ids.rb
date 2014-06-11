class DdeLegacyNationalIds < ActiveRecord::Base
  self.table_name = 'legacy_national_ids'
  default_scope {where(voided: 0)}
  belongs_to :person, :class_name => 'DdePerson'
end
