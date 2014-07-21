LogProg = Logger.new(Rails.root.join("log","progress.log"))

def get_national_ids
   DdeNationalPatientIdentifier.all
end

def get_sites
   DdeSite.where("id > 1")
end

def get_people
   DdePerson.limit(10)
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
  

 File.open(Rails.root.join("docs","people.txt"), 'a') { |file| file.write('{"docs":[') }
  
 people.each do |person|
 next if person.national_patient_identifier.value.blank?
 person_hash = Hash.new
 person_hash =   {
				  				 :_id => (person.national_patient_identifier.value),
									 :assigned_site =>  (person.national_patient_identifier.assigner_site.code rescue "998"),
									 :patient_assigned => true,
									 :person_attributes => { 
		                                       :citizenship => (person.data["attributes"]["citizenship"] rescue nil),
																					 :occupation => (person.data["attributes"]["occupation"] rescue nil),
																					 :home_phone_number => (person.data["attributes"]["home_phone_number"] rescue nil),
																					 :cell_phone_number => (person.data["attributes"]["cell_phone_number"] rescue nil),
		                                       :office_phone_number => (person.data["attributes"]["office_phone_number"] rescue nil),
																					 :race => (person.data["attributes"]["race"] rescue nil),
														              },

										:gender => (person.data["gender"] rescue ""),

										:names => { 
		                            :given_name => (person.data["names"]["given_name"] rescue ""),
									 					    :family_name => (person.data["names"]["family_name"] rescue ""),
		                            :given_name_code => (person.person_name_codes.first.given_name_code rescue nil),
									 					    :family_name_code => (person.person_name_codes.first.family_name_code rescue nil),
														  },

										:birthdate => (person.data["birthdate"] rescue nil),
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
		     
		     
          File.open(Rails.root.join("docs","people.txt"), 'a') do |file| 
               file.write(person_hash.to_json)
               file.write(" , ") if counter < 9
          end

          puts person_hash.to_json
          counter +=1  
          #message = "Migrated >>>> #{ counter} of #{total_people} people"
          #LogProg.info message
          #puts message

		      #if person_saved 
		      #    @national_id = Npid.find_by_national_id(@person.national_id)
		      #    unless @national_id.blank?
		      #      @national_id.assigned = true
		      #      @national_id.site_code = @person.assigned_site
		      #      @national_id.save!
		      #    end
		      #end
 end
  File.open(Rails.root.join("docs","people.txt"), 'a') { |file| file.write(' ] }') }
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
   site_code = DdeSite.find(national_id.assigner_site_id).code rescue nil
   site_code = "999" if national_id.assigner_site_id == "999"
   site_code = "998" if national_id.assigner_site_id == "998"
    
    regions = Hash["312" => "Centre", "XXL" => "Centre", "696"  => "Centre", "MPC" => "Centre", "NAH" => "Centre",
                "526" => "Centre", "CHA"  => "Centre", "MTA" => "Centre", "KHC" => "Centre","A18" => "Centre",
                "MIT" => "Centre", "KAN"  => "Centre", "MHC" => "Centre", "LIK" => "Centre","NHC" => "Centre",
                "DLH" => "Centre" , "DOW" => "Centre", "STG" => "Centre", "CVR" => "Centre","EXC" => "Centre",
                "DZA" => "Centre" , "NCH" => "Centre", "KAS" => "Centre", "MZC" => "North","QCH" => "South",
                "MAL" => "South" , "MLB" => "South", "PMH" => "South","MJD" => "South", "BHC" => "South", "NDC" => "South",
								"999" => "999", "998" => "998"]
    
   @npid = Npid.find_by_national_id(national_id.value)
   unless @npid.blank?
     @npid.site_code = site_code
  	 @npid.assigned = national_id.assigned_at.blank? ? false : true
     @npid.assigned = true if regions[site_code] == "EXC"
     @npid.region = regions[site_code] rescue ""
     @npid.save! 
   end

   counter +=1  
   message = "Updated >>>> #{counter} of #{total_national_ids} national_ids"
   LogProg.info message
   puts message						 
 end 
end

def create_sites
 sites = get_sites
 total_sites = sites.count
 counter = 0
 regions = Hash["312" => "Centre", "XXL" => "Centre", "696"  => "Centre", "MPC" => "Centre", "NAH" => "Centre",
                "526" => "Centre", "CHA"  => "Centre", "MTA" => "Centre", "KHC" => "Centre","A18" => "Centre",
                "MIT" => "Centre", "KAN"  => "Centre", "MHC" => "Centre", "LIK" => "Centre","NHC" => "Centre",
                "DLH" => "Centre" , "DOW" => "Centre", "STG" => "Centre", "CVR" => "Centre","EXC" => "Centre",
                "DZA" => "Centre" , "NCH" => "Centre", "KAS" => "Centre", "MZC" => "North","QCH" => "South",
                "MAL" => "South" , "MLB" => "South", "PMH" => "South","MJD" => "South", "BHC" => "South", "NDC" => "South"]
 message = "Creating sites"
 LogProg.info message
 puts message
 sites.each do |site|
    @dde_site = Site.new 
    @dde_site.site_code = site.code
    @dde_site.name = site.name
    @dde_site.description = site.annotations
    @dde_site.region = regions[site.code] rescue ""
    @dde_site.save!
   	counter +=1  
   	message = "Created >>>> #{counter} of #{total_sites} sites"
  	 LogProg.info message
     puts message						 
 end 
end

start = Time.now()
#create_sites
migrate_people
#migrate_footprints
#update_national_ids

puts "Started at: #{start.strftime("%Y-%m-%d %H:%M:%S")} ########## finished at:#{Time.now().strftime("%Y-%m-%d %H:%M:%S")}"
