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
       
        view :by__id,
            :map => "function(doc) {
                if ((doc['type'] == 'npid') && (doc['_id'] != null)) {
                  emit(doc['_id'], 1);
                }
              }"   
        view :by_national_id,
            :map => "function(doc) {
                if ((doc['type'] == 'npid') && (doc['_national_id'] != null)) {
                  emit(doc['_national_id'], 1);
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
        view :by_national_id
        
    end
  end

end
