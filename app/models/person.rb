require 'couchrest_model'

class Person < CouchRest::Model::Base

  use_database "person"
  
  def national_id
    self['_id']
  end

  def national_id=(value)
    self['_id']=value
  end

  property :assigned_site, String
  property :patient_assigned, TrueClass, :default => false

  property :person_attributes  do
    property :country_of_residence, String
    property :citizenship, String
    property :occupation, String
    property :home_phone_number, String
    property :cell_phone_number, String
    property :office_phone_number, String
    property :race, String
  end

  property :gender, String

  property :names do
    property :given_name, String
    property :family_name, String
    property :middle_name, String
    property :maiden_name, String
    property :given_name_code, String
    property :family_name_code, String
  end

  property :patient do
    property :identifiers, []
  end

  property :birthdate, String
  property :birthdate_estimated,  TrueClass, :default => false

  property :addresses do
    property :current_residence, String
    property :current_village, String
    property :current_ta, String
    property :current_district, String
    property :home_village, String
    property :home_ta, String
    property :home_district, String
  end
   
  property :old_identification_number, String

  timestamps!


  design do
    view :by__id,
         :map => "function(doc) {
                  if ((doc['type'] == 'Person') && (doc['_id'] != null) && doc['assigned_site'] != '???') {
                    emit(doc['_id'], 1);
                  }
                }"
                
    view :by_old_identification_number
    
    view :by_created_at
    
    view :by_updated_at
    
    view :by_assigned_site,
         :map => "function(doc) {
                  if ((doc['type'] == 'Person') && (doc['assigned_site'] != null) && doc['assigned_site'] != '???') {
                    emit(doc['assigned_site'], 1);
                  }
                }"
                
    view :by_gender,
         :map => "function(doc) {
                  if ((doc['type'] == 'Person') && (doc['gender'] != null) && doc['assigned_site'] != '???') {
                    emit(doc['gender'], 1);
                  }
                }"
                
    view :by_gender_and_assigned_site, 
         :map => "function(doc) {
                  if ((doc['type'] == 'Person') && (doc['gender'] != null) && (doc['assigned_site'] != null) && doc['assigned_site'] != '???') {
                    emit([doc['gender'], doc['assigned_site']], 1);
                  }
                }"
  end

  design do
    view :search,
         :map => "function(doc){
            if (doc['type'] == 'Person' && doc['assigned_site'] != '???' ){
              emit([doc.names.given_name_code ,doc.names.family_name_code, doc.gender], null);
            }
          }"

    view :advanced_search,
         :map => "function(doc){
            if (doc['type'] == 'Person' && doc['assigned_site'] != '???' ){
              emit([doc.names.given_name_code,doc.names.family_name_code, doc.gender, (new Date(doc.birthdate)).getFullYear(),doc.addresses.home_ta ,doc.addresses.home_district], null);
            }
          }"

    view :search_with_dob,
         :map => "function(doc){
            if (doc['type'] == 'Person' && doc['assigned_site'] != '???' ){
              emit([doc.names.given_name_code ,doc.names.family_name_code, doc.gender, (new Date(doc.birthdate)).getFullYear()], null);
            }
          }"
    view :search_with_home_district,
         :map => "function(doc){
            if (doc['type'] == 'Person' && doc['assigned_site'] != '???' ){
              emit([doc.names.given_name_code ,doc.names.family_name_code, doc.gender, doc.addresses.home_district], null);
            }
          }"
    view :search_with_home_ta,
         :map => "function(doc){
            if (doc['type'] == 'Person' && doc['assigned_site'] != '???' ){
              emit([doc.names.given_name_code ,doc.names.family_name_code, doc.gender, doc.addresses.home_ta], null);
            }
          }"
    view :search_with_home_ta_district,
         :map => "function(doc){
            if (doc['type'] == 'Person' && doc['assigned_site'] != '???' ){
              emit([doc.names.given_name_code ,doc.names.family_name_code, doc.gender, doc.addresses.home_ta, doc.addresses.home_district], null);
            }
          }"
    view :search_with_dob_home_ta,
         :map => "function(doc){
            if (doc['type'] == 'Person' && doc['assigned_site'] != '???' ){
              emit([doc.names.given_name_code ,doc.names.family_name_code, doc.gender,(new Date(doc.birthdate)).getFullYear() ,doc.addresses.home_ta], null);
            }
          }"
    view :search_with_dob_home_district,
         :map => "function(doc){
            if (doc['type'] == 'Person' && doc['assigned_site'] != '???' ){
              emit([doc.names.given_name_code ,doc.names.family_name_code, doc.gender, (new Date(doc.birthdate)).getFullYear(),doc.addresses.home_district], null);
            }
          }"
    view :search_by_all_identifiers,
         :map => "function(doc) {
	          if ((doc['type'] == 'Person' && doc['assigned_site'] != '???' && doc['patient']['identifiers'].length > 0)) {
		          for(var i in doc['patient']['identifiers']){
              	  		emit(doc['patient']['identifiers'][i][Object.keys(doc['patient']['identifiers'][i])[0]], 1);
		          }		          
	          }
          }"
    view :by_voided,
         :map => "function(doc) {
              if(doc.assigned_site == '???'){
                emit(doc._id, null);
              }
            }"
    view :by_temporary_id,
         :map => "function(doc) {
          	String.prototype.checkDigit = function(){
          		var digits = this.trim().replace(/-/,'').split('').reverse();         
          		var sum = 0;          
          		for(var i = 0; i < digits.length; i++){          
            			var digit = parseInt(digits[i]);            
            			if(i % 2 > 0){            
              				digit *= 2;              
              				if(digit > 9){              
                				var num = String(digit).split('');                
                				digit = 0;                
                				for(var j = 0; j < num.length; j++){                  
                  					digit += parseInt(num[j]);                
                				}              
              				}            
            			}            
            			sum += digit;          
          		}          
          		return (sum * 9) % 10;
	        };
	        String.prototype.toDecimal = function(){
          		var separator = '-'
          		// we are taking out letters B, I, O, Q, S, Z because they might be
          		// mistaken for 8, 1, 0, 0, 5, 2 respectively
          		var base_map = ['0','1','2','3','4','5','6','7','8','9','A','C','D','E','F','G',
                        	'H','J','K','L','M','N','P','R','T','U','V','W','X','Y'];                      
          		var reverse_map = {'0' : 0,'1' : 1,'2' : 2,'3' : 3,'4' : 4,'5' : 5,
                           '6' : 6,'7' : 7,'8' : 8,'9' : 9,
                           'A' : 10,'C' : 11,'D' : 12,'E' : 13,'F' : 14,'G' : 15,
                           'H' : 16,'J' : 17,'K' : 18,'L' : 19,'M' : 20,'N' : 21,
                           'P' : 22,'R' : 23,'T' : 24,'U' : 25,'V' : 26,'W' : 27,
                           'X' : 28,'Y' : 29};                           
           		var decimal = 0;           
           		var num = this.replace(/-/,'').split('').reverse();           
           		for(var i = 0; i < num.length; i++){           
              			decimal += reverse_map[num[i]] * Math.pow(30, i);            
           		}             
           		return decimal;                 
	        };
	        var decimal = doc._id.trim().toDecimal();	
	        if(String(parseInt(decimal / 10)).checkDigit() != (decimal % 10) && doc.type == 'Person'){
		        emit(doc._id, null);
	        }
        }"
  end

  def set_name_codes
    self.names.given_name_code = self.names.given_name.soundex unless self.names.given_name.blank?
    self.names.family_name_code = self.names.family_name.soundex unless self.names.family_name.blank?
  end

end
