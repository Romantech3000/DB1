/*======================================================================
		Города, области и страны
  ======================================================================*/
USE `db_lesson4`;

CREATE OR REPLACE VIEW `moscow_region` AS
	SELECT `cities`.`name` AS `Город`, `regions`.`name` AS `Область` , `countries`.`name` AS `Страна`
	FROM `cities` 
	LEFT JOIN `regions` ON `cities`.`region_id` = `regions`.id
	LEFT JOIN `countries` ON `cities`.`country_id` = `countries`.id
	WHERE `cities`.`region_id` = 
		(SELECT `id` FROM `regions` WHERE `name` = 'Московская' LIMIT 1)
;

SELECT * FROM `moscow_region`;

SET @fake_id := 0;

# 1287 Setting user variables within expressions is deprecated and will be removed in a future release. 
# Consider alternatives: 'SET variable=expression, ...', or 'SELECT expression(s) INTO variables(s)'.
delimiter $$
CREATE FUNCTION get_fake_id()
RETURNS INT(11)
READS SQL DATA
BEGIN
	SET @fake_id := @fake_id + 1;
	RETURN @fake_id;
END;
$$
delimiter ;

#DROP FUNCTION `get_fake_id`;

/* 	Removing data columns that seem to be redundant for a list of places located
	in the same region of the same country.
	Tried adding an id column, just as a simple counter
    SELECT in VIEW still can't contain variables (Error 1351), 
	I couldn't find a proper way to generate an auto-increment id column for the view
	nothing but a UUID() worked, which creates new values on every SELECT of the view 
	Used get_fake_id function with a separate variable, but couldn't find a way to reset
    the counter value for every new SELECT. 
    Possibly a transaction setting and re-setting @fake_id could be a solution*/
   
ALTER VIEW `moscow_region` AS
	SELECT get_fake_id() AS `id`, `cities`.`name` AS `Город` FROM `cities` 
		WHERE `cities`.`region_id` = 
			(SELECT `id` FROM `regions` WHERE `name` = 'Московская' LIMIT 1)
;

SELECT * FROM `moscow_region`;
SET @fake_id := 0;

#DROP VIEW `moscow_region`;


/*======================================================================
		Отделы и сотрудники
  ======================================================================*/

/* Средняя зарплата (по отделам) */
CREATE OR REPLACE VIEW `avarage_dep_salaries` AS
	SELECT `dep_id` AS `id`, `departments`.`name` AS `Отдел`, avg(`salary`) AS `Средняя з/п` FROM `employees`
	INNER JOIN `departments` ON `dep_id` = `departments`.`id` 
	GROUP BY `dep_id` 
	ORDER BY `departments`.`name` ASC;
    
SELECT * FROM `avarage_dep_salaries`;

/* just checking if views are OK with getting a single value */
CREATE OR REPLACE VIEW `min_salary` AS 
	SELECT max(`salary`) AS `Максимальная зарплата` FROM `employees`;

SELECT * FROM `min_salary`;

CREATE FUNCTION get_manager_id (firstName VARCHAR(45), lastName VARCHAR(45))
RETURNS INT(11) DETERMINISTIC
READS SQL DATA
RETURN (
	SELECT `id` FROM `employees` 
	WHERE `first_name` = firstName AND `last_name` = lastName AND `job_title` = 'менеджер'
    LIMIT 1
);

SELECT * FROM `employees` WHERE `id` = get_manager_id('Анна', 'Конева');

/* if first and last name pair of an employee is not unique, we should at least 
be geting some warning concerning it */
CREATE FUNCTION `get_employee_info` (firstName VARCHAR(45), lastName VARCHAR(45))
RETURNS VARCHAR(100) DETERMINISTIC
READS SQL DATA
RETURN(
	SELECT concat(`first_name`, ' ', `last_name`, ', ',`job_title`, ', зарплата: ', `salary`) 
	FROM `employees` WHERE `first_name` = firstName AND `last_name` = lastName LIMIT 1
);

#DROP FUNCTION `get_employee_info`;

SELECT `get_employee_info` ('Алексей', 'Пушкин') AS `Информация о сотруднике`;

delimiter $$

CREATE PROCEDURE get_employee_fields(IN firstName VARCHAR(45), IN lastName VARCHAR(45))
READS SQL DATA
BEGIN
	SET @temp_id = (SELECT `id` FROM `employees` WHERE `first_name` = firstName AND `last_name` = lastName LIMIT 1);
    SELECT * FROM `employees` WHERE `id` = @temp_id;
END;
$$

delimiter ;
#DROP PROCEDURE `get_employee_info`;

CALL get_employee_fields('Алексей', 'Пушкин');

delimiter $$

CREATE TRIGGER `new_employee` AFTER INSERT ON `employees`
	FOR EACH ROW
    BEGIN
		INSERT INTO `salary` (`emp_id`, `payment`) VALUES (NEW.id, NEW.salary * 0.5);
	END; #sometimes the semicolon is there, sometimes it's not in MySQL docs
$$
    
delimiter ;

INSERT INTO `employees` (`last_name`, `first_name`, `job_title`, `dep_id`, `salary`) VALUES
('Волков', 'Иван', 'стрелок', 4, 55000.00),
('Медведев', 'Семён', 'самурай', 4, 75000.00);

SELECT * FROM `salary` 
	WHERE `emp_id` IN (
		SELECT `id` FROM `employees` 
			WHERE (`last_name` = 'Волков' AND `first_name` = 'Иван') 
				OR (`last_name` = 'Медведев' AND `first_name` = 'Семён')
	)
;
    
SELECT * FROM `salary` ORDER BY `id` DESC LIMIT 2;
