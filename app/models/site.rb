require 'couchrest_model'

class Site < CouchRest::Model::Base

  use_database "person"
 
  def site_code=(value)
    self['_id']=value
  end

  def site_code
      self['_id']
  end

  property :name, String
  property :description, String
  property :region, String
  property :threshold, Integer, :default => 10
  property :batch_size, Integer, :default => 100
  property :site_id_count, Integer, :default => 0
  property :x, String
  property :y, String
  property :site_type, String, :default => "proxy"  # Either master/proxy
  property :ip_address, String, :default => "127.0.0.1"
  property :username, String, :default => "admin"
  property :password, String, :default => "test"
  property :site_db1, String
  property :site_db2, String
  
  timestamps!

  def self.current     
     return self.by__id.key(self.current_code).first
  end

  def self.current_name
     return self.current.try(:name) || 'Master Service'
  end

  def self.current_code

    if CONFIG["sitecode"].blank?
       settings = YAML.load_file(Rails.root.join('config', 'couchdb.yml'))[Rails.env] rescue nil
    else
       settings = CONFIG
    end

    return settings["sitecode"]

  end

  def self.current_region

    if CONFIG["region"].blank?
       settings = YAML.load_file(Rails.root.join('config', 'couchdb.yml'))[Rails.env]
    else
       settings = CONFIG
    end

    return settings["region"]

  end

  def self.where(params = {})
    result = []
    
    if !params[:region].blank?
      result = Site.all.collect { |site|
        site if site.region.downcase.strip == params[:region].to_s.strip.downcase
      }.compact.uniq
    end
    
    result
  end

  design do
    view :by__id
    
    view :list,
          :map => "function(doc){
            if (doc['type'] == 'Site'){
              emit(doc._id, {site_code: doc._id, name: doc.name, region: doc.region, x: doc.x, 
                y: doc.y, description: doc.description, threshold: doc.threshold,
                batch_size: doc.batch_size, site_type: doc.site_type, ip_address: doc.ip_address,
                site_id_count: doc.site_id_count});
            }
          }"
  end

end
