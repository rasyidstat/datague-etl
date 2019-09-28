# datague-etl

ETL scripts for my personal analytics project, DataGue using R and PostgreSQL as the data storage

## Naming conventions

Naming conventions for `datague-etl`

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

## Data Checklist

My post about personal analytics can be accessed [here](http://rasyidridha.com/blog/personal-analytics/) and [here](http://rasyidridha.com/blog/collect-all-the-data/). My goal is to build the data foundation of my personal analytics system which is simple and automated.

There are limitless data in our life. I will focus primarily to track my financial and transportation data.




