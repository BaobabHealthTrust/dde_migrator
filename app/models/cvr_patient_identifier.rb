class CvrNationalPatientIdentifier < ActiveRecord::Base
  self.table_name = 'national_identifiers'
  default_scope { where("decimal_num IS NOT NULL", voided: 0 ) }
end
