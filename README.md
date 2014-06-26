== DDE Migration Script

This application is made for mysql to couchdb DDE migration.

Insructions:

* 1.Copy config/database.yml.example to config/database.yml

* 2.Configure your config/database.yml file to point to your source database

* 3.Copy config/couchdb.yml.example to config/couchdb.yml

* 4.Configure config/couchdb.yml file to point to your destination database

* 5.Copy config/site_config.yml.example to config/site_config.yml and configure if necessary

* 6.Finally run rails runner -e [development | production ]

* 7.Observe the script progress...
