require 'couchrest_model'
class Dde2Footprint < CouchRest::Model::Base
  
  use_database "person"
 
  property :npid, String
  property :application, String
  property :site_code, String
  
  timestamps!

  design do
    view :by__id

    view :where_gone,
       :map => "function(doc) {
            if (doc['type'] == 'Footprint') {
              emit(doc.npid, {application: doc.application, site: doc.site_code, when: doc.updated_at});
            }
          }"

    view :existing,
       :map => "function(doc) {
            if (doc['type'] == 'Footprint') {
              emit([doc.npid, doc.application, doc.site_code, (new Date(doc.updated_at)).getFullYear(), ((new Date(doc.updated_at)).getMonth() + 1), (new Date(doc.updated_at)).getDate()], {application: doc.application, site: doc.site_code, when: doc.updated_at});
            }
          }"
  end

end
