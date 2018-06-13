# datague-etl

## Naming conventions

Naming conventions for `datakepo-etl`

* __First prefix__ - type of script
	* `r_` __executor__ - run all scripts and write into DB
	* `d_` __data maker__ - create cleaned data
	* `c_` __config__ - script parameters
* __Second prefix__ - data source
	* `_tl_` TapLog
	* `_ifttt_` IFTTT
	* `_sb_` SuperBackup
* __Third prefix__ - table name
	* `_transport` Transport
	* `_food` Food
	* `_banking` Banking
	* `_spending` Spending
	* `_ecommerce` E-commerce
