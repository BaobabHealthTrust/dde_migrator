require 'couchrest_model'
class User < CouchRest::Model::Base
  
  use_database "local"
    
  def username
   self['_id']
  end

  def username=(value)
   self['_id'] = value
  end
 
  property :first_name, String
  property :last_name, String
  property :password, String
  property :email, String
  property :active, TrueClass, :default => true
  property :notify, TrueClass, :default => false
  property :role, String
  property :site_code, String
  property :creator, String
  
  timestamps!

end
