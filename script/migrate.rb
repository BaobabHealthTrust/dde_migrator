LogProg = Logger.new(Rails.root.join("log","progress.log"))

def get_national_ids
   CvrPersonIdentifier.where('person_id IS NOT NULL')
end

def get_people
   CvrPerson.all
end

def self.migrate_people
 people = get_people
 total_people = people.count
 counter = 0
 message = "Migrating people"
 LogProg.info message
 puts message
  
 file_name = "#{rand(10000)}.txt"
 File.open(Rails.root.join("docs",file_name), 'a') { |file| file.write('{"docs":[') }
  
 people.each do |person|
 next if person.national_id.blank?
 
 person_hash = Hash.new
 
 national_id = CvrPersonIdentifier.find_by_id(person.national_id)
 personA = Person.find(national_id.identifier)
 next if personA.present?
 person_hash =   {
				  				 :_id => (national_id.identifier),
				  				 :national_id => (national_id.identifier),
									 :assigned_site =>  (national_id.site_id.upcase),
									 :created_at => person.created_at,
									 :patient_assigned => true,
									 :person_attributes => { 
		                                       :citizenship => (""),
																					 :home_phone_number => (""),
																					 :cell_phone_number => (""),
		                                       :office_phone_number => (""),
																					 :race => (""),
														              },

										:gender => (person.gender.first rescue nil),

										:names => { 
		                            :given_name => (person.given_name rescue ""),
									 					    :family_name => (person.family_name rescue ""),
		                            :given_name_code => (person.given_name_code rescue nil),
									 					    :family_name_code => (person.family_name_code rescue nil),
														  },

										:birthdate => (person.birthdate rescue nil),
										:birthdate_estimated => (person.birthdate_estimated rescue nil),

										:addresses => {
																   :current_village => (person.village rescue nil),
																   :current_ta => (person.ta rescue nil),
																   :current_district => (person.state_province rescue nil),
																   :home_village => (person.neighborhood_cell rescue nil),
																   :home_ta => (person.county_district rescue nil),
																   :home_district => ("")
				                          }
		         
		      }
		      
          personC = Person.create(person_hash)
          
          if personC.present?
            counter += 1
            message = "Wrote >>>> #{ counter} of #{total_people} people"
         		LogProg.info message
            puts message
          else
          	message = "Not written"
	          LogProg.info message
	          puts message
          end
          
end
end

def self.update_national_ids
 nationalids = get_national_ids
 total_national_ids = nationalids.count
 counter = 0
 message = "Updating national ids"
 LogProg.info message
 puts message
 regions = Hash["312" => "Centre", "XXL" => "Centre", "696"  => "Centre", "MPC" => "Centre", "NAH" => "Centre",
                "526" => "Centre", "CHA"  => "Centre", "MTA" => "Centre", "KHC" => "Centre","A18" => "Centre",
                "MIT" => "Centre", "KAN"  => "Centre", "MHC" => "Centre", "LIK" => "Centre","NHC" => "Centre",
                "DLH" => "Centre" , "DOW" => "Centre", "STG" => "Centre", "CVR" => "Centre","EXC" => "Centre",
                "DZA" => "Centre" , "NCH" => "Centre", "KAS" => "Centre", "MZC" => "North","QCH" => "South",
                "MAL" => "South" , "MLB" => "South", "PMH" => "South","MJD" => "South", "BHC" => "South", "NDC" => "South",
								"999" => "999", "998" => "998"]
    
 nationalids.each do |national_id| 
   @npid = Npid.by_national_id.key(national_id.identifier).first rescue nil
   
   if @npid.present?
     if @npid.assigned == false
		   @npid.site_code = national_id.site_id.upcase
			 @npid.assigned = national_id.person_id.blank? ? false : true
		   @npid.region = regions[site_code] rescue ""
		   @npid.save! 
		   counter +=1  
			 message = "Updated >>>> #{counter} of #{total_national_ids} national_ids"
			 LogProg.info message
			 puts message	   
		 else 
       counter +=1  
			 message = "Could not update: >>>> #{@npid.national_id}"
			 LogProg.info message
			 puts message	  
   	 end
   end
   					 
 end 
end

start = Time.now()

migrate_people
update_national_ids

#update_national_ids
#create_sites
#migrate_people
#migrate_footprints
#update_national_ids

puts "Started at: #{start.strftime("%Y-%m-%d %H:%M:%S")} ########## finished at:#{Time.now().strftime("%Y-%m-%d %H:%M:%S")}"
