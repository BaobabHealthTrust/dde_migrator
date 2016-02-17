LogProg = Logger.new(Rails.root.join("log","reclaiming_progress.log"))

people = Person.by_created_at.startkey("2016-01-01 00:00:00").endkey("2016-02-16 23:59:59")

counter = 0
people.each do |person|
 next if person.patient.blank?
 next if person.patient.identifiers.blank?
 old_id = person.patient.identifiers.first['Old Identification Number'] 
 if old_id.present? && old_id.length == 6 && (NationalPatientId.valid?(NationalPatientId.to_decimal(old_id.upcase)) rescue false) && (old_id != old_id.upcase) 
  puts old_id + " : " + (NationalPatientId.valid?(NationalPatientId.to_decimal(old_id.upcase)) rescue false).to_s + " : " + person.created_at.to_s	
 	counter +=1

     legacy_id = old_id.upcase
 
     		  found_person = Person.find(legacy_id)
     		  if found_person.blank?
     		  	npid = Npid.by_national_id.key(legacy_id).first rescue nil
     		  	if npid.present?
     		  	  if npid.person_assigned.blank? || npid.person_assigned == false
     		  	    reclaim_id = person.national_id
     		  	    person.national_id = npid.national_id
     		  	    person.save
     		  	    npid.person_assigned = true
     		  	    npid.save
     		  	    message = "Reclaimed " + person.national_id.to_s
 								LogProg.info message
 								puts message
     		  	    reclaimed_id = Npid.by_national_id.key(reclaim_id) rescue nil
     		  	    if reclaimed_id.present?
		   		  	    reclaimed_id.person_assigned = false
		   		  	    reclaimed_id.save
     		  	    end
     		  	    
     		  	    local_national_id = CvrPersonIdentifier.where("identifier = #{reclaim_id} AND identifier_type = 3")
     		  	    local_legacy_id = CvrPersonIdentifier.where("identifier = #{legacy_id} AND identifier_type = 2")
     		  	    
     		  	    if local_national_id.present? && local_legacy_id.present?
     		  	    
     		  	       local_legacy_id.update_attributes(:void => true, 
     		  	       																	 :voided_by => 1, 
     		  	       																	 :date_voided => Date.today, 
     		  	       																	 :void_reason => "DDE2 ID re-assigment")
     		  	       																	 
     		  	       local_national_id.update_attributes(:void => true, 
     		  	       																		 :voided_by => 1, 
     		  	       																		 :date_voided => Date.today, 
     		  	       																		 :void_reason => "DDE2 ID re-assigment")
     		  	       																		 
     		  	       CvrPersonIdentifier.create(:patient_id => CvrPersonIdentifier.patient_id, 
     		  	       														:identifier => local_legacy_id.identifier,
     		  	       														:identifier_type => 3,
     		  	       														:location_id => 700,
     		  	       														:creator => 1,
     		  	       														:date_created => Date.today)
     		  	
     		  	    end
     		  	  end
     		  	end
     		  end
end
puts counter.to_s	
