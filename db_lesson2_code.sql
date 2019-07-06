/* in real applications mysqldump would likely be used to copy the schema
 in MySQL Workbench the following works fine
 */
CREATE SCHEMA IF NOT EXISTS `db_lesson2` DEFAULT CHAR SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS db_lesson2.countries LIKE db_lesson1.countries;
CREATE TABLE IF NOT EXISTS db_lesson2.regions LIKE db_lesson1.regions;
CREATE TABLE IF NOT EXISTS db_lesson2.cities_towns LIKE db_lesson1.cities_towns;

USE `db_lesson2`;

/* just didn't copy it while creating tables for the new schema
 DROP TABLE `districts`; */

/* increasing the name field size from 45 to 150 characters*/
ALTER TABLE `countries` MODIFY COLUMN `name` VARCHAR(150) NOT NULL;

ALTER TABLE `regions`
	/* increasing the name field size from 45 to 150 characters
     and moving to the 3rd position to match the condition of the task */
	MODIFY COLUMN `name` VARCHAR(150) NOT NULL AFTER `country_id`,
	MODIFY COLUMN `country_id` INT(11) NOT NULL, 
	ADD INDEX (`name`),
	ADD INDEX (`country_id`),
	ADD CONSTRAINT `fk_region_countries` FOREIGN KEY (`country_id`) 
		REFERENCES `countries` (`id`) 
			ON DELETE RESTRICT
			ON UPDATE CASCADE;

RENAME TABLE `cities_towns` TO `cities`;

ALTER TABLE `cities`
	DROP COLUMN `district_id`,
	ADD COLUMN `country_id` INT(11) NOT NULL AFTER `id`,
	ADD COLUMN `important` TINYINT(1) NOT NULL AFTER `country_id`,
	MODIFY COLUMN `name` VARCHAR(150) NOT NULL AFTER `region_id`,
	MODIFY COLUMN `region_id` INT(11) NOT NULL,
	ADD INDEX (`name`),
    ADD INDEX (`country_id`),
    ADD INDEX (`region_id`),
	ADD CONSTRAINT `fk_city_countries` FOREIGN KEY (`country_id`)
		REFERENCES `countries` (`id`)
			ON DELETE RESTRICT
			ON UPDATE CASCADE,
	ADD CONSTRAINT `fk_city_regions` FOREIGN KEY (`region_id`)
		REFERENCES `countries` (`id`)
			ON DELETE RESTRICT
			ON UPDATE CASCADE
;

SHOW CREATE TABLE `cities`;
SHOW COLUMNS FROM `cities`;
/*
 I kept getting an error while trying to create an FK for the table `cities` 
 with the same name (fk_countries) as an existing FK for a table `regions`.
 
 https://dev.mysql.com/doc/refman/5.6/en/create-table-foreign-keys.html
 If the CONSTRAINT symbol clause is given, the symbol value, if used, 
 must be unique in the database. A duplicate symbol will result in 
 an error similar to: ERROR 1022 (2300): Can't write; duplicate key 
 in table '#sql- 464_1'. If the clause is not given, or a symbol is 
 not included following the CONSTRAINT keyword, a name for the constraint 
 is created automatically. 
 */
 
 