SHOW VARIABLES LIKE '%isolat%';
SET transaction_isolation = SERIALIZABLE;
SELECT @@SESSION.autocommit;
SET autocommit = 0;

USE `db_lesson5`;

SHOW INDEX FROM `employees`;

####### TRANSACTIONS #######

# delete 1 top wage employee
BEGIN;
SET @max_sal = (SELECT max(`salary`) FROM `employees`);
SET @max_sal_id = (SELECT `id` FROM `employees` WHERE `salary` = @max_sal LIMIT 1);
DELETE FROM `employees` WHERE `id` = @max_sal_id;
COMMIT;
# instead of
DELETE FROM `employees` 
	WHERE `id` = (
		SELECT `id` FROM `employees` 
			WHERE `salary` = (SELECT max(`salary`) FROM `employees`) 
			LIMIT 1
	)
;


/* setting the actual number of employees for all departments
I wonder if there's a better way to do it */
UPDATE `departments` d1
LEFT JOIN (
	SELECT d.`id` AS `j_id`, COUNT(*) AS `new_count` FROM `departments` d 
	LEFT JOIN `employees` e ON e.`dep_id` = d.`id` GROUP BY `dep_id`
) j ON d1.id = j.j_id
SET d1.`count` = j.new_count WHERE id > 0
;

/* we could use a trigger to increment departments.count when adding a new employee
or a transaction as follows*/    
BEGIN;
SET @dest_dep_id = 4;
INSERT INTO `employees` (`last_name`, `first_name`, `job_title`, `dep_id`, `salary`) VALUES
('Лосев', 'Иннокентий', 'связист', @dest_dep_id, 51000.00);
UPDATE `departments` SET `count` = `count` + 1 WHERE id = @dest_dep_id;
ROLLBACK;


####### EXPLAIN #######

EXPLAIN SELECT * FROM `salary` 
	WHERE `emp_id` IN (
		SELECT `id` FROM `employees` 
			WHERE (`last_name` = 'Волков' AND `first_name` = 'Иван') 
				OR (`last_name` = 'Медведев' AND `first_name` = 'Семён')
	)
;

/*
+----+-------------+-----------+------------+--------+-------------------+---------+---------+--------------------------+------+----------+-------------+
| id | select_type | table     | partitions | type   | possible_keys     | key     | key_len | ref                      | rows | filtered | Extra       |
+----+-------------+-----------+------------+--------+-------------------+---------+---------+--------------------------+------+----------+-------------+
|  1 | SIMPLE      | salary    | NULL       | ALL    | emp_id            | NULL    | NULL    | NULL                     |    2 |   100.00 | NULL        |
|  1 | SIMPLE      | employees | NULL       | eq_ref | PRIMARY,last_name | PRIMARY | 4       | db_lesson5.salary.emp_id |    1 |     6.25 | Using where |
+----+-------------+-----------+------------+--------+-------------------+---------+---------+--------------------------+------+----------+-------------+
seemingly low search efficiency (6.25) doesn't seem to be affected by the existing last_name index.
adding first_name index or last and first name compound index doesn't change the result
ALTER TABLE `employees`
ADD INDEX `last_first_name` (`last_name`, `first_name`);
etc.
*/

EXPLAIN SELECT * FROM `cities` WHERE `name` LIKE 'М%';
/*
+----+-------------+--------+------------+-------+---------------+------+---------+------+------+----------+-----------------------+
| id | select_type | table  | partitions | type  | possible_keys | key  | key_len | ref  | rows | filtered | Extra                 |
+----+-------------+--------+------------+-------+---------------+------+---------+------+------+----------+-----------------------+
|  1 | SIMPLE      | cities | NULL       | range | name          | name | 602     | NULL |    2 |   100.00 | Using index condition |
+----+-------------+--------+------------+-------+---------------+------+---------+------+------+----------+-----------------------+
Huge key length
*/

/* Complex query explain. Full info on places within Moscow region */
EXPLAIN 
	SELECT `cities`.`name` AS `Город`, `regions`.`name` AS `Область` , `countries`.`name` AS `Страна`
	FROM `cities` 
	LEFT JOIN `regions` ON `cities`.`region_id` = `regions`.id
	LEFT JOIN `countries` ON `cities`.`country_id` = `countries`.id
	WHERE `cities`.`region_id` = 
		(SELECT `id` FROM `regions` WHERE `name` = 'Московская' LIMIT 1)
;
/*
+----+-------------+-----------+------------+--------+---------------+-----------+---------+------------------------------+------+----------+-------------+
| id | select_type | table     | partitions | type   | possible_keys | key       | key_len | ref                          | rows | filtered | Extra       |
+----+-------------+-----------+------------+--------+---------------+-----------+---------+------------------------------+------+----------+-------------+
|  1 | PRIMARY     | cities    | NULL       | ref    | region_id     | region_id | 4       | const                        |    8 |   100.00 | Using where |
|  1 | PRIMARY     | regions   | NULL       | eq_ref | PRIMARY       | PRIMARY   | 4       | const                        |    1 |   100.00 | Using where |
|  1 | PRIMARY     | countries | NULL       | eq_ref | PRIMARY       | PRIMARY   | 4       | db_lesson5.cities.country_id |    1 |   100.00 | NULL        |
|  2 | SUBQUERY    | regions   | NULL       | ref    | name          | name      | 602     | const                        |    1 |   100.00 | Using index |
+----+-------------+-----------+------------+--------+---------------+-----------+---------+------------------------------+------+----------+-------------+
*/