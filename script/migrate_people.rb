def get_people
 people = DdePerson.all
end

def build_dde2_person
 people = get_people

 people.each do |person|
   puts person.inspect
 end
end

build_dde2_person
