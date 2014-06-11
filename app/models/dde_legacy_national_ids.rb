class DdeLegacyNationalIds < ActiveRecord::Base
  self.table_name = 'legacy_national_ids'
  default_scope where(:voided => false)
  belongs_to :ddeperson
end
