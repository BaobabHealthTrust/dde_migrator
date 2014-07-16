class DdeNationalPatientIdentifierOriginal < ActiveRecord::Base
  establish_connection :originalmaster
  self.table_name = 'national_patient_identifiers'
  default_scope { where("decimal_num IS NOT NULL", voided: 0 ) }
  belongs_to :person, :class_name => 'DdePerson'
  belongs_to :assigner, :class_name => 'DdeUser'
  belongs_to :assigner_site, :class_name => 'DdeSite', :foreign_key => 'assigner_site_id'

  validates_presence_of :value, :assigner_site_id

  # don't allow more than one ID to be assigned to any person
  validates_uniqueness_of :person_id, :allow_nil => true

  # create the decimal equivalent of the Id value if it has not yet been set
  before_save do |npid|
    if npid.decimal_num.blank?
      num = NationalPatientId.to_decimal(npid.value, 30) / 10
      npid.decimal_num = num
    end
  end
  
  

  def self.find_or_create_from_attributes(attrs, options = {:update => false})
    if attrs['value']
      self.find_or_initialize_by_value(attrs['value']).tap do |npid|
        npid.update_attributes(attrs) if npid.new_record? or options[:update]
      end
    else
      raise ArgumentError, %q(expected attrs hash to have key named 'value')
    end
  end

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
