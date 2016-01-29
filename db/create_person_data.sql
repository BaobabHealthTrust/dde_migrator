
DROP TABLE IF EXISTS `person_data` ;

CREATE TABLE IF NOT EXISTS `person_data` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `person_id` int(11) NOT NULL,
  `citizenship` varchar(40) DEFAULT NULL,
  `race` varchar(40) DEFAULT NULL,
  `occupation` varchar(40) DEFAULT NULL,
  `cell_phone_number` varchar(40) DEFAULT NULL,
  `home_phone_number` varchar(40) DEFAULT NULL,
  `office_phone_number` varchar(40) DEFAULT NULL,
  `current_residence` varchar(40) DEFAULT NULL,
  `current_village` varchar(40) DEFAULT NULL,
  `current_ta` varchar(40) DEFAULT NULL,
  `current_district` varchar(40) DEFAULT NULL,
  `home_village` varchar(40) DEFAULT NULL,
  `home_ta` varchar(40) DEFAULT NULL,
  `home_district` varchar(40) DEFAULT NULL,
  `legacy_ids` varchar(100) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
