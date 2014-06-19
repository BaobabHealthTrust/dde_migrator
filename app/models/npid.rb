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
    if Rails.env.downcase == "production"
        # NOTE: all occurences of "doc['type'] == 'npid'" are using lowercase type
        # which is different from the way CouchRest::Model creates its type field
        # which is normally "Npid" instead. This is due to the way initialisation
        # data was created which helps bring a difference between manually
        # generated data and that from the application. This is the case mainly
        # because data in this group of documents is expected to be pre-generated 
        # externally and just consumed by the application.
        
        # Site views
        view :unassigned_to_site,
             :map => "function(doc){
                if (doc['type'] == 'npid' && doc['site_code'] == ''){
                      emit(doc.national_id, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, updated_at: doc.updated_at});
                }
              }"
        view :unassigned_at_site,
             :map => "function(doc){
                if (doc['type'] == 'npid' && doc['site_code'] == '#{Site.current_code}' && !doc.assigned ){
                  emit(doc.national_id, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, updated_at: doc.updated_at});
                }
              }"
        view :assigned_at_site,
             :map => "function(doc){
                if (doc['type'] == 'npid' && doc['site_code'] == '#{Site.current_code}' && doc.assigned ){
                  emit(doc.national_id, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, updated_at: doc.updated_at});
                }
              }"
        view :assigned_to_site,
             :map => "function(doc){
                if (doc['type'] == 'npid' && doc['site_code'] == '#{Site.current_code}' ){
                  emit(doc.national_id, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, updated_at: doc.updated_at});
                }
              }"
              
        # Current Region views    
        view :unassigned_to_region,
             :map => "function(doc){
                if (doc['type'] == 'npid' && (doc['region'] == '' || doc['region'] == null)){
                      emit(doc.national_id, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :unassigned_at_this_region,
             :map => "function(doc){
                if (doc['type'] == 'npid' && doc['region'] == '#{Site.current_region}' && (doc['site_code'] == '' || doc['site_code'] == null) ){
                  emit(doc.region, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :assigned_at_this_region,
             :map => "function(doc){
                if (doc['type'] == 'npid' && doc['region'] == '#{Site.current_region}' && (doc['site_code'] != '' && doc['site_code'] != null) && doc.assigned ){
                  emit(doc.national_id, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :assigned_to_this_region,
             :map => "function(doc){
                if (doc['type'] == 'npid' && doc['region'] == '#{Site.current_region}' ){
                  emit(doc.national_id, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :untaken_at_this_region,
             :map => "function(doc){
                if (doc['type'] == 'npid' && doc['region'] == '#{Site.current_region}' && (doc['site_code'] != '' && doc['site_code'] != null) && !doc.assigned ){
                  emit(doc.region, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        # General views
        view :unassigned_at_region,
             :map => "function(doc){
                if (doc['type'] == 'npid' && (doc['site_code'] == '' || doc['site_code'] == null) ){
                  emit(doc.region, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :assigned_at_region,
             :map => "function(doc){
                if (doc['type'] == 'npid' && (doc['site_code'] != '' && doc['site_code'] != null) && doc.assigned ){
                  emit(doc.site_code, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :assigned_to_region,
             :map => "function(doc){
                if (doc['type'] == 'npid' && doc['region'] != '' && doc['region'] != null ){
                  emit(doc.site_code, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :untaken_at_region,
             :map => "function(doc){
                if (doc['type'] == 'npid' && doc['region'] != '' && doc['region'] != null && (doc['site_code'] != '' && doc['site_code'] != null) && !doc.assigned ){
                  emit(doc.site_code, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
              
        # Central Region views 
        view :unassigned_at_central_region,
             :map => "function(doc){
                if (doc['type'] == 'npid' && doc['region'] == 'Centre' && (doc['site_code'] == '' || doc['site_code'] == null) ){
                  emit(doc.region, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :assigned_at_central_region,
             :map => "function(doc){
                if (doc['type'] == 'npid' && doc['region'] == 'Centre' && (doc['site_code'] != '' && doc['site_code'] != null) && doc.assigned ){
                  emit(doc.national_id, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :allocated_to_central_region,
             :map => "function(doc){
                if (doc['type'] == 'npid' && doc['region'] == 'Centre' ){
                  emit(doc.national_id, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :available_at_central_region,
             :map => "function(doc){
                if (doc['type'] == 'npid' && doc['region'] == 'Centre' && (doc['site_code'] != '' && doc['site_code'] != null) && !doc.assigned ){
                  emit(doc.region, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
              
        # Northern Region views 
        view :unassigned_at_northern_region,
             :map => "function(doc){
                if (doc['type'] == 'npid' && doc['region'] == 'North' && (doc['site_code'] == '' || doc['site_code'] == null) ){
                  emit(doc.region, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :assigned_at_northern_region,
             :map => "function(doc){
                if (doc['type'] == 'npid' && doc['region'] == 'North' && (doc['site_code'] != '' && doc['site_code'] != null) && doc.assigned ){
                  emit(doc.national_id, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :allocated_to_northern_region,
             :map => "function(doc){
                if (doc['type'] == 'npid' && doc['region'] == 'North' ){
                  emit(doc.national_id, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :available_at_northern_region,
             :map => "function(doc){
                if (doc['type'] == 'npid' && doc['region'] == 'North' && (doc['site_code'] != '' && doc['site_code'] != null) && !doc.assigned ){
                  emit(doc.region, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
              
        # Southern Region views 
        view :unassigned_at_southern_region,
             :map => "function(doc){
                if (doc['type'] == 'npid' && doc['region'] == 'South' && (doc['site_code'] == '' || doc['site_code'] == null) ){
                  emit(doc.region, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :assigned_at_southern_region,
             :map => "function(doc){
                if (doc['type'] == 'npid' && doc['region'] == 'South' && (doc['site_code'] != '' && doc['site_code'] != null) && doc.assigned ){
                  emit(doc.national_id, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :allocated_to_southern_region,
             :map => "function(doc){
                if (doc['type'] == 'npid' && doc['region'] == 'South' ){
                  emit(doc.national_id, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :available_at_southern_region,
             :map => "function(doc){
                if (doc['type'] == 'npid' && doc['region'] == 'South' && (doc['site_code'] != '' && doc['site_code'] != null) && !doc.assigned ){
                  emit(doc.region, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"    
        view :by__id,
            :map => "function(doc) {
                if ((doc['type'] == 'npid') && (doc['_id'] != null)) {
                  emit(doc['_id'], 1);
                }
              }"   
        view :by__national_id,
            :map => "function(doc) {
                if ((doc['type'] == 'npid') && (doc['_national_id'] != null)) {
                  emit(doc['_national_id'], 1);
                }
              }" 
        view :by_site_code,
            :map => "function(doc) {
                if ((doc['type'] == 'npid') && (doc['site_code'] != null)) {
                  emit(doc['site_code'], 1);
                }
              }"
        view :all,
            :map => "function(doc) {
              if (doc['type'] == 'npid') {
                emit(doc._id, null);
              }
            }"
    else 
        # NOTE: this set of views is created specifically for "development" and 
        # "test" environments only and not to be used in "production" mode.
        
        view :by__id
        view :by__national_id
        view :by_site_code
    
        # Site views
        view :unassigned_to_site,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['site_code'] == ''){
                      emit(doc.national_id, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, updated_at: doc.updated_at});
                }
              }"
        view :unassigned_at_site,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['site_code'] == '#{Site.current_code}' && !doc.assigned ){
                  emit(doc.national_id, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, updated_at: doc.updated_at});
                }
              }"
        view :assigned_at_site,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['site_code'] == '#{Site.current_code}' && doc.assigned ){
                  emit(doc.national_id, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, updated_at: doc.updated_at});
                }
              }"
        view :assigned_to_site,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['site_code'] == '#{Site.current_code}' ){
                  emit(doc.national_id, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, updated_at: doc.updated_at});
                }
              }"
              
        # Current Region views    
        view :unassigned_to_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && (doc['region'] == '' || doc['region'] == null)){
                      emit(doc.national_id, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :unassigned_at_this_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] == '#{Site.current_region}' && (doc['site_code'] == '' || doc['site_code'] == null) ){
                  emit(doc.region, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :assigned_at_this_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] == '#{Site.current_region}' && (doc['site_code'] != '' && doc['site_code'] != null) && doc.assigned ){
                  emit(doc.national_id, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :assigned_to_this_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] == '#{Site.current_region}' ){
                  emit(doc.national_id, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :untaken_at_this_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] == '#{Site.current_region}' && (doc['site_code'] != '' && doc['site_code'] != null) && !doc.assigned ){
                  emit(doc.region, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        # General views
        view :unassigned_at_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && (doc['site_code'] == '' || doc['site_code'] == null) ){
                  emit(doc.region, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :assigned_at_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && (doc['site_code'] != '' && doc['site_code'] != null) && doc.assigned ){
                  emit(doc.site_code, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :assigned_to_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] != '' && doc['region'] != null ){
                  emit(doc.site_code, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :untaken_at_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] != '' && doc['region'] != null && (doc['site_code'] != '' && doc['site_code'] != null) && !doc.assigned ){
                  emit(doc.site_code, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
              
        # Central Region views 
        view :unassigned_at_central_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] == 'Centre' && (doc['site_code'] == '' || doc['site_code'] == null) ){
                  emit(doc.region, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :assigned_at_central_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] == 'Centre' && (doc['site_code'] != '' && doc['site_code'] != null) && doc.assigned ){
                  emit(doc.national_id, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :allocated_to_central_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] == 'Centre' ){
                  emit(doc.national_id, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :available_at_central_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] == 'Centre' && (doc['site_code'] != '' && doc['site_code'] != null) && !doc.assigned ){
                  emit(doc.region, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
              
        # Northern Region views 
        view :unassigned_at_northern_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] == 'North' && (doc['site_code'] == '' || doc['site_code'] == null) ){
                  emit(doc.region, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :assigned_at_northern_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] == 'North' && (doc['site_code'] != '' && doc['site_code'] != null) && doc.assigned ){
                  emit(doc.national_id, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :allocated_to_northern_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] == 'North' ){
                  emit(doc.national_id, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :available_at_northern_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] == 'North' && (doc['site_code'] != '' && doc['site_code'] != null) && !doc.assigned ){
                  emit(doc.region, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
              
        # Southern Region views 
        view :unassigned_at_southern_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] == 'South' && (doc['site_code'] == '' || doc['site_code'] == null) ){
                  emit(doc.region, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :assigned_at_southern_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] == 'South' && (doc['site_code'] != '' && doc['site_code'] != null) && doc.assigned ){
                  emit(doc.national_id, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :allocated_to_southern_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] == 'South' ){
                  emit(doc.national_id, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
        view :available_at_southern_region,
             :map => "function(doc){
                if (doc['type'] == 'Npid' && doc['region'] == 'South' && (doc['site_code'] != '' && doc['site_code'] != null) && !doc.assigned ){
                  emit(doc.region, {id: doc._id ,national_id: doc.national_id, site_id: doc.site_code, assigned: doc.assigned, region: doc.region, updated_at: doc.updated_at});
                }
              }"
    end
    
  end

end
