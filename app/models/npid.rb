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
    view :by__id
    view :by_national_id 
  end

end
