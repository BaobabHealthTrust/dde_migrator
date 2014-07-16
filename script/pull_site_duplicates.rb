LogProg = Logger.new(Rails.root.join("log","compared_id_progress.log"))
LogIds =  Logger.new(Rails.root.join("log","duplicate_ids.log"))

def get_original_ids
  DdeNationalPatientIdentifierOriginal.all
end

def compare_values
 national_ids = get_original_ids

 national_ids.each do |national_id|
	 updated_national_id = DdeNationalPatientIdentifier.find_by_value(national_id.value)
   unless updated_national_id.blank?
     if updated_national_id.assigner_site_id != national_id.assigner_site_id
       msg = "#{national_id.value} was created for #{national_id.assigner_site_id} but assigned to #{updated_national_id.assigner_site_id}"
       LogProg.info msg
       LogIds.info national_id.value
       puts msg
     else
       puts "#{national_id.value} was created for #{national_id.assigner_site_id} and assigned to #{updated_national_id.assigner_site_id}"
     end
   end
   
 end

end

start = Time.now()
compare_values
puts "Started at: #{start.strftime("%Y-%m-%d %H:%M:%S")} ########## finished at:#{Time.now().strftime("%Y-%m-%d %H:%M:%S")}"
