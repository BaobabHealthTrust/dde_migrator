require 'couchrest_model'

class Npid < CouchRest::Model::Base

  def incremental_id=(value)
    self['_id']=value.to_s
  end

  def incremental_id
      self['_id']
  end

  property :national_id, String  
  property :site_code, String
  property :assigned, TrueClass, :default => false
  property :region, String
  
  timestamps!
  
  # Can be replaced with "Npid.by_site_code.include_docs.keys([SITE_CODE]).page(PAGE).per(PAGE_SIZE).rows"
  def self.where(params = {})
    result = []
    limit = 0
    
    if !params[:site].blank? and !params[:start].nil? and !params[:limit].nil? and params[:start].strip.downcase == "last"
      
      # npids = Npid.assigned_to_region.collect{|e| e if (e.site_code.downcase.strip == params[:site].strip.downcase rescue false)}.compact.uniq
      
      npids = Npid.assigned_to_region.keys([params[:site].strip]).rows
      
      limit = npids.length
      
      if npids.length > 0
      
        params[:start] = ((npids.length / params[:limit].to_i) * params[:limit].to_i)
        
        params[:start] = (params[:start].to_i - params[:limit].to_i) if (params[:start].to_i == npids.length)
        
        ((params[:start].to_i)..(npids.length - 1)).each do |i|
           
          npids[i]["value"] = Npid.find_by__id(npids[i].id) rescue {}
          
          person = Person.find_by__id(npids[i]["value"]["national_id"]) rescue nil
          
          result << {
            npid: npids[i]["value"]["national_id"],
            assigned: npids[i]["value"]["assigned"],
            region: npids[i]["value"]["region"],
            sitecode: npids[i]["value"]["site_code"],
            name: ("#{person.names.given_name} #{person.names.family_name}" rescue nil),
            updated: ((npids[i]["value"]["updated_at"]).to_time.strftime("%Y-%m-%d %H:%M") rescue nil),
            pos: npids[i]["value"]["id"]
          } 
          
        end
      
      else
        params[:start] = 0
      end
      
    elsif !params[:site].blank? and !params[:start].nil? and !params[:limit].nil?

      # npids = Npid.assigned_to_region.collect{|e| e if (e.site_code.downcase.strip == params[:site].strip.downcase rescue false)}.compact.uniq
      
      npids = Npid.assigned_to_region.keys([params[:site].strip]).rows
      
      # raise (npids[0]["value"]).inspect
      
      # raise (npids[0]["value"]["updated_at"]).to_time.strftime("%Y-%m-%d %H:%M").inspect
      
      if npids.length > 0
      
        limit = npids.length
      
        params[:limit] = (npids.length - params[:start].to_i) if ((params[:start].to_i + params[:limit].to_i - 1) > npids.length)
        
        # raise "#{params[:limit]} : #{params[:start]} : #{npids.length}"
        
        ((params[:start].to_i)..(params[:start].to_i + params[:limit].to_i - 1)).each do |i|
           
          npids[i]["value"] = Npid.find_by__id(npids[i].id) rescue {}
          
          person = Person.find_by__id(npids[i]["value"]["national_id"]) rescue nil
          
          result << {
            npid: npids[i]["value"]["national_id"],
            assigned: npids[i]["value"]["assigned"],
            region: npids[i]["value"]["region"],
            sitecode: npids[i]["value"]["site_code"],
            name: ("#{person.names.given_name} #{person.names.family_name}" rescue nil),
            updated: ((npids[i]["value"]["updated_at"]).to_time.strftime("%Y-%m-%d %H:%M") rescue nil),
            pos: npids[i]["value"]["id"]
          } 
          
        end
      
      else
        params[:start] = 0
      end
        
    end
    
    [result, params[:start], limit]
  end

  design do
        view :by__id
        view :by_national_id
        view :by_site_code
        view :by_assigned
        view :by_site_code_and_assigned
    
        # Site views
        view :unassigned_to_site,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['site_code'] == ''){
                      emit(doc.national_id, null);
                }
              }"
        view :unassigned_at_site,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['site_code'] == 'KCH' && !doc.assigned ){
                  emit(doc.national_id, null);
                }
              }"
        view :assigned_at_site,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['site_code'] == 'KCH' && doc.assigned ){
                  emit(doc.national_id, null);
                }
              }"
        view :assigned_to_site,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['site_code'] == 'KCH' ){
                  emit(doc.national_id, null);
                }
              }"
              
        # Current Region views    
        view :unassigned_to_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && (doc['region'] == '' || doc['region'] == null)){
                      emit(doc.national_id, null);
                }
              }"
        view :assigned_at_this_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] == 'Centre' && (doc['site_code'] != '' && doc['site_code'] != null) && doc.assigned ){
                  emit(doc.national_id, null);
                }
              }"
        # General views
        view :assigned_at_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && (doc['site_code'] != '' && doc['site_code'] != null) && doc.assigned ){
                  emit(doc.site_code, null);
                }
              }"
        view :assigned_to_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] != '' && doc['region'] != null ){
                  emit(doc.site_code, null);
                }
              }"
        view :untaken_at_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] != '' && doc['region'] != null && (doc['site_code'] != '' && doc['site_code'] != null) && !doc.assigned ){
                  emit(doc.site_code, null);
                }
              }"
              
        # Central Region views 
        view :unassigned_at_central_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] == 'Centre' && (doc['site_code'] == '' || doc['site_code'] == null) ){
                  emit(doc.region, null);
                }
              }"
        view :assigned_at_central_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] == 'Centre' && (doc['site_code'] != '' && doc['site_code'] != null) && doc.assigned ){
                  emit(doc.national_id, null);
                }
              }"
        view :allocated_to_central_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] == 'Centre' ){
                  emit(doc.national_id, null);
                }
              }"
        view :available_at_central_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] == 'Centre' && (doc['site_code'] != '' && doc['site_code'] != null) && !doc.assigned ){
                  emit(doc.region, null);
                }
              }"
              
        # Northern Region views 
        view :unassigned_at_northern_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] == 'North' && (doc['site_code'] == '' || doc['site_code'] == null) ){
                  emit(doc.region, null);
                }
              }"
        view :assigned_at_northern_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] == 'North' && (doc['site_code'] != '' && doc['site_code'] != null) && doc.assigned ){
                  emit(doc.national_id, null);
                }
              }"
        view :allocated_to_northern_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] == 'North' ){
                  emit(doc.national_id, null);
                }
              }"
        view :available_at_northern_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] == 'North' && (doc['site_code'] != '' && doc['site_code'] != null) && !doc.assigned ){
                  emit(doc.region, null);
                }
              }"
              
        # Southern Region views 
        view :unassigned_at_southern_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] == 'South' && (doc['site_code'] == '' || doc['site_code'] == null) ){
                  emit(doc.region, null);
                }
              }"
        view :assigned_at_southern_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] == 'South' && (doc['site_code'] != '' && doc['site_code'] != null) && doc.assigned ){
                  emit(doc.national_id, null);
                }
              }"
        view :allocated_to_southern_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] == 'South' ){
                  emit(doc.national_id, null);
                }
              }"
        view :available_at_southern_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] == 'South' && (doc['site_code'] != '' && doc['site_code'] != null) && !doc.assigned ){
                  emit(doc.region, null);
                }
              }"
    
  end
  
  

end
