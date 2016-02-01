LogProg = Logger.new(Rails.root.join("log","progress.log"))
LogPersonMigrateSuccess = Logger.new(Rails.root.join("log","person_success.log"))
LogPersonMigrateFail = Logger.new(Rails.root.join("log","person_fail.log"))
LogNpidMigrateSuccess = Logger.new(Rails.root.join("log","npid_success.log"))
LogNpidSuccessFail = Logger.new(Rails.root.join("log","npid_fail.log"))
LogNpidNotFound = Logger.new(Rails.root.join("log","npid_not_found.log"))
LogNpidInvalid = Logger.new(Rails.root.join("log","npid_invalid.log"))

def get_people
   CvrPerson.all
end

def self.migrate_people
 people = get_people
 total_people = people.count
 message = "Migrating people"
 LogProg.info message
 puts message
 
 counter = 0
 personSuccessCounter = 0
 personFailCounter = 0
 npidSuccessCounter = 0
 npidFailCounter = 0
 npidInvalid = 0
 
 regions = Hash["312" => "Centre", "XXL" => "Centre", "696"  => "Centre", "MPC" => "Centre", "NAH" => "Centre",
                "526" => "Centre", "CHA"  => "Centre", "MTA" => "Centre", "KHC" => "Centre","A18" => "Centre",
                "MIT" => "Centre", "KAN"  => "Centre", "MHC" => "Centre", "LIK" => "Centre","NHC" => "Centre",
                "DLH" => "Centre" , "DOW" => "Centre", "STG" => "Centre", "CVR" => "Centre","EXC" => "Centre",
                "DZA" => "Centre" , "NCH" => "Centre", "KAS" => "Centre", "MZC" => "North","QCH" => "South",
                "MAL" => "South" , "MLB" => "South", "PMH" => "South","MJD" => "South", "BHC" => "South", "NDC" => "South",
								"999" => "999", "998" => "998"]

 people.each do |person|
 next if person.national_id.blank?
 
 national_id = CvrPersonIdentifier.find_by_id(person.national_id)
 
 to_decimal = NationalPatientId.to_decimal(national_id.identifier) rescue nil
 if to_decimal.blank?
    message = "Invalid ID #{person.national_id}"
    LogNpidInvalid.info message
    puts message
    npidInvalid +=1
    counter +=1
    message = "Read >>>> #{counter} of #{total_people} people"
    LogProg.info message
    puts message
    next
 else
    if NationalPatientId.valid?(to_decimal) == false
     	message = "Invalid ID #{person.national_id}"
    	LogNpidInvalid.info message
		  puts message
		  npidInvalid +=1
		  counter +=1
		  message = "Read >>>> #{counter} of #{total_people} people"
		  LogProg.info message
		  puts message
		  next
    end
 end
  
 personA = Person.find(national_id.identifier)
 #### 
 if personA.present?
 	personA.destroy
 end
 personA = Person.find(national_id.identifier) 
 #### 
 person_hash = Hash.new
 
 if personA.blank?
 
 current_national_id = national_id.identifier
 
 if current_national_id.length == 13 and current_national_id.first.upcase == "P"
  current_national_id = Npid.by_site_code_and_assigned.keys([[national_id.site_id.upcase, false]]).first.id rescue national_id.identifier
 end
 
 person_hash =   {
				  				 :_id => (current_national_id),
				  				 :national_id => (current_national_id),
									 :assigned_site =>  (national_id.site_id.upcase),
									 :created_at => person.created_at,
									 :patient_assigned => true,
									 :patient => { :identifiers => [{"National id" => current_national_id}] },
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
		                            :given_name_code => (person.given_name.soundex),
									 					    :family_name_code => (person.family_name.soundex),
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
            personSuccessCounter += 1
            message = "Read >>>> #{counter} of #{total_people} people"
         		LogProg.info message
            puts message
            message = "Written,#{person.given_name},#{person.family_name},#{national_id.identifier}"
            LogPersonMigrateSuccess.info message
            puts message
            counter +=1
            npid = Npid.by_national_id.key(current_national_id).first rescue nil
   
					  if npid.present?
						   if npid.assigned == false
							   npid.site_code = national_id.site_id.upcase
							   npid.assigned = national_id.person_id.blank? ? false : true
								 npid.region = regions[site_code] rescue ""
								 npid.save! 
								 message = "Updated NPID ,#{person.given_name},#{person.family_name},#{national_id.identifier}"
            		 LogNpidMigrateSuccess.info message
            		 npidSuccessCounter += 1
            		 puts message  
							 else
								 message = "Not Updated NPID #{current_national_id}, It already belongs to someone else"
								 LogNpidSuccessFail.info message
								 puts message	
								 npidFailCounter += 1  
						 	 end
						 else
						     message = "Not found NPID #{current_national_id}"
								 LogNpidNotFound.info message
								 puts message	
								 npidFailCounter += 1   	 
						 end
          else
          	message = "Not Written,#{person.given_name},#{person.family_name}, person with id: #{current_national_id} already exists"
	          LogPersonMigrateFail.info message
	          puts message
	          personFailCounter +=1
	          counter +=1
	          message = "Read >>>> #{counter} of #{total_people} people"
         		LogProg.info message
         		puts message
          end
         
	else
	  message = "Not Written,#{person.given_name},#{person.family_name}, person with id: #{national_id.identifier} already exists"
    LogPersonMigrateFail.info message
    puts message
    personFailCounter +=1
    counter +=1
    message = "Read >>>> #{counter} of #{total_people} people"
    LogProg.info message
    puts message
	end
	end	
	puts "People Migrated: #{personSuccessCounter}"
	puts "People Not Migrated: #{personFailCounter}"
	puts "NPID Updated: #{npidSuccessCounter}"
	puts "NPID Not Updated #{npidFailCounter}"
end

start = Time.now()

migrate_people

puts "Started at: #{start.strftime("%Y-%m-%d %H:%M:%S")}"
puts "Finished at: #{Time.now().strftime("%Y-%m-%d %H:%M:%S")}"
