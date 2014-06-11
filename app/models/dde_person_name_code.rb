class DdePersonNameCode < ActiveRecord::Base
  self.table_name = 'person_name_codes'
  belongs_to :ddeperson, :foreign_key => :id

  def self.create_name_code(person)
    found = self.find_by_person_id(person.id)
    return if person.given_name.blank?
    return if person.family_name.blank?
    return unless person.given_name.match(/[0-9]/).blank?
    return unless person.family_name.match(/[0-9]/).blank?
    
    if found.blank?
      self.create(:person_id => person.id,
                :given_name_code => person.given_name.soundex,
                :family_name_code => person.family_name.soundex)
    else
      found.given_name_code = person.given_name.soundex
      found.family_name_code = person.family_name.soundex
      found.save
    end           
  end

  def self.rebuild_person_name_codes
    DdePersonNameCode.delete_all
    people = Person.find(:all)
    people.each {|person|
      DdePersonNameCode.create(
        :person_id => person.id,
        :given_name_code => (person.given_name || '').soundex,
        :family_name_code => (person.family_name || '').soundex
      )
    }
  end
  
end
