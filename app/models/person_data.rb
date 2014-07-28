class PersonData < ActiveRecord::Base
   self.table_name = 'person_data'
   belongs_to :person, :class_name => 'DdePerson'
end
