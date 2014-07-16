LogProg = Logger.new(Rails.root.join("log","progress.log"))

def get_national_ids
   DdeNationalPatientIdentifier.all
end

def get_people
   DdePerson.all
end

def get_footprints
   DdeMasterFootprint.all
end

def migrate_people
 people = get_people
 total_people = people.count
 counter = 0
 message = "Migrating people"
 LogProg.info message
 puts message

 people.each do |person|
 person_hash = Hash.new
 person_hash =   {
				  				 :national_id => person.national_patient_identifier.value,
									 :assigned_site =>  person.national_patient_identifier.assigner_site.code,
									 :patient_assigned => true,
									 :person_attributes => { 
		                                       :citizenship => (person.data["attributes"]["citizenship"] rescue nil),
																					 :occupation => (person.data["attributes"]["occupation"] rescue nil),
																					 :home_phone_number => (person.data["attributes"]["home_phone_number"] rescue nil),
																					 :cell_phone_number => (person.data["attributes"]["cell_phone_number"] rescue nil),
		                                       :office_phone_number => (person.data["attributes"]["office_phone_number"] rescue nil),
																					 :race => (person.data["attributes"]["race"] rescue nil),
														              },

										:gender => person.data["gender"],

										:names => { 
		                            :given_name => person.data["names"]["given_name"],
									 					    :family_name => person.data["names"]["family_name"],
		                            :given_name_code => (person.person_name_codes.first.given_name_code rescue nil),
									 					    :family_name_code => (person.person_name_codes.first.family_name_code rescue nil),
														  },

										:birthdate => (person.data["birth_date"] rescue nil),
										:birthdate_estimated => (person.data["birthdate_estimated"] rescue nil),

										:addresses => {
																   :current_village => (person.data["addresses"]["city_village"] rescue nil),
																   :current_ta => (person.data["addresses"]["address1"] rescue nil),
																   :current_district => (person.data["addresses"]["state_province"] rescue nil),
																   :home_village => (person.data["addresses"]["neighborhood_cell"] rescue nil),
																   :home_ta => (person.data["addresses"]["county_district"] rescue nil),
																   :home_district => (person.data["addresses"]["address2"] rescue nil)
				                          }
		         
		      }

		       if person.legacy_national_ids
		             old_identifiers = []
		             person.legacy_national_ids.each do |legacy_id|
		               old_identifier_hash = {:old_identification_number => legacy_id.value}
		               old_identifiers << old_identifier_hash
		             end 
		            person_hash.merge!(:patient => {:identifiers => old_identifiers})
		       end
		     
		      @person = Person.new(person_hash)
		      person_saved = @person.save!
          counter +=1  
          message = "Migrated >>>> #{ counter} of #{total_people} people"
          LogProg.info message
          puts message

		      if person_saved 
		          @national_id = Npid.find_by_national_id(@person.national_id)
		          unless @national_id.blank?
		            @national_id.assigned = true
		            @national_id.site_code = @person.assigned_site
		            @national_id.save!
		          end
		      end
 end
end

def migrate_footprints
 footprints = get_footprints
 total_footprints = footprints.count
 counter = 0
 message = "Migrating footprints"
 LogProg.info message
 puts message
 footprints.each do |footprint|
   site_code = DdeSite.find(footprint.site_id).code
   
   @dde_footprint = Footprint.new(:npid => footprint.value,
																 :application =>  footprint.application_name,
																 :site_code => site_code,
														     :created_at => footprint.interaction_datetime,
														     :updated_at => footprint.interaction_datetime)

   dde_person = @dde_footprint.save!

   counter +=1  
   message = "Migrated >>>> #{counter} of #{total_footprints} footprints"
   LogProg.info message
   puts message
								 
   
 end 
end

def update_national_ids
 nationalids = get_national_ids
 total_national_ids = nationalids.count
 counter = 0
 message = "Updating national ids"
 LogProg.info message
 puts message
 nationalids.each do |national_id|
   site_code = DdeSite.find(footprint.site_id).code
   
   @dde_footprint = Footprint.new(:npid => footprint.value,
																 :application =>  footprint.application_name,
																 :site_code => site_code,
														     :created_at => footprint.interaction_datetime,
														     :updated_at => footprint.interaction_datetime)

   dde_person = @dde_footprint.save!

   counter +=1  
   message = "Migrated >>>> #{counter} of #{total_footprints} footprints"
   LogProg.info message
   puts message
								 
   
 end 
end



start = Time.now()
migrate_people
migrate_footprints
puts "Started at: #{start.strftime("%Y-%m-%d %H:%M:%S")} ########## finished at:#{Time.now().strftime("%Y-%m-%d %H:%M:%S")}"
