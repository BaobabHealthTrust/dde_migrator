people = Person.by_created_at.startkey("2016-02-15 00:00:00").endkey("2016-02-16 23:59:59").each

people.each do |person|
 next if person.patient.blank?
 next if person.patient.identifiers.blank?
 
 person.patient.identifiers.each do |identifier|
     legacy_id = identifier["Old Identification Number"]
     if legacy_id.present? && legacy_id.length == 6
        legacy_id = legacy_id.upcase
     		if NationalPatientId.valid?(NationalPatientId.to_decimal(legacy_id)) rescue false
     		  person = Person.find(legacy_id)
     		  if person.blank?
     		  	npid = Npid.by_national_id.key(legacy_id).first rescue nil
     		  	if npid.present?
     		  	  if npid.person_assigned.blank? || npid.person_assigned == false
     		  	    reclaim_id = person.national_id
     		  	    person.national_id = Npid.national_id
     		  	    person.save
     		  	    npid.person_assigned = true
     		  	    npid.save
     		  	    reclaimed_id = Npid.by_national_id.key(reclaim_id) rescue nil
     		  	    if reclaimed_id.present?
		   		  	    reclaimed_id.person_assigned = false
		   		  	    reclaimed_id.save
     		  	    end
     		  	    
     		  	    local_national_id = CvrPersonIdentifier.where("identifier = #{reclaim_id} AND identifier_type = 3")
     		  	    local_legacy_id = CvrPersonIdentifier.where("identifier = #{legacy_id} AND identifier_type = 4")
     		  	    
     		  	    if local_national_id.present? && local_legacy_id.present
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
     		  	    else
     		  	    end
     		  	    
     		  	    
     		  	    
     		  	  else
     		  	  end
     		  	else
     		  	end
     		  else
     		  end
     		end
     end
 end
 
end
