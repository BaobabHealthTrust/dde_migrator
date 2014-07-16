class DdeNationalPatientIdentifierOriginal < ActiveRecord::Base
  establish_connection :originalmaster
  self.table_name = 'national_patient_identifiers'
  default_scope { where("decimal_num IS NOT NULL", voided: 0 ) }
  
  validates_presence_of :value, :assigner_site_id

  # don't allow more than one ID to be assigned to any person
  validates_uniqueness_of :person_id, :allow_nil => true

  def remote_attributes
    { 'npid' => {
        'value'            => self.value,
        'assigner_site_id' => self.assigner_site_id,
        'assigned_at'      => self.assigned_at
      }
    }
  end

  def to_json
    self.remote_attributes.to_json
  end

  def self.get_national_patient_identifier
    self.order('id ASC').where(:'person_id' => nil).first rescue nil
  end

  def self.get_blank_decimal_num_identifier(person_id)
    self.find_by_sql("SELECT * FROM national_patient_identifiers 
    WHERE person_id = #{person_id} AND decimal_num IS NULL").first rescue nil
  end

  def force_void(message = nil)
    sql =<<EOF
    UPDATE national_patient_identifiers SET person_id = NULL,voided = 1,
    void_reason = "#{message}",voided_date = '#{Time.now().strftime('%Y-%m-%d %H:%M:%S')}'
    WHERE id = #{self.id}
EOF

    ActiveRecord::Base.connection().execute(sql)
  end

end
