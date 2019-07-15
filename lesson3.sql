/*======================================================================
		Города, области и страны
  ======================================================================*/

CREATE SCHEMA IF NOT EXISTS `db_lesson3` DEFAULT CHAR SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE `db_lesson3`;

CREATE TABLE `countries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(150) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `country_name_UNIQUE` (`name`)
);


CREATE TABLE `regions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `country_id` int(11) NOT NULL,
  `name` varchar(150) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `name` (`name`),
  KEY `country_id` (`country_id`),
  CONSTRAINT `fk_region_countries` FOREIGN KEY (`country_id`) 
	REFERENCES `countries` (`id`)
		ON UPDATE CASCADE
        ON DELETE RESTRICT
);


CREATE TABLE `cities` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `country_id` int(11) NOT NULL,
  `important` tinyint(1) NOT NULL DEFAULT 0, # DEF is not mentioned in the homework
  `region_id` int(11) NOT NULL,
  `name` varchar(150) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `name` (`name`),
  KEY `country_id` (`country_id`),
  KEY `region_id` (`region_id`),
  CONSTRAINT `fk_city_countries` FOREIGN KEY (`country_id`) 
	REFERENCES `countries` (`id`)
		ON UPDATE CASCADE
        ON DELETE RESTRICT,
  CONSTRAINT `fk_city_regions` FOREIGN KEY (`region_id`) 
	REFERENCES `regions` (`id`)
		ON UPDATE CASCADE
        ON DELETE RESTRICT
);



#TRUNCATE TABLE `countries`;

/* Workbench suggests Dropping and re-creating the corresponding FK
for this alteration (DROP FOREIGN KEY, CHANGE COLUMN, ADD CONSTRAINT) 
ALTER TABLE `cities` MODIFY COLUMN `region_id` INT(11) NOT NULL;
*/

INSERT INTO `countries` (`name`) VALUES
('Австрия'),
('Россия'),
('Германия'),
('Антигуа и Барбуда'),
('Беларусь'),
('Венгрия'),
('Австралия'),
('Тринидад и Тобаго');


#TRUNCATE TABLE `regions`;
INSERT INTO `regions` (`country_id`, `name`) VALUES
(2,'Амурская'),
(2,'Архангельская'),
(2,'Астраханская'),
(2,'Ленинградская'),
(2,'Московская'),
(2,'Мурманская'),
(2,'Новосибирская'),
(2,'Омская'),
(2,'Тюменская'),
(5,'Брестская'),
(5,'Гомельская'),
(5,'Витебская'),
(5,'Могилёвская'),
(5,'Минская'),
(5,'Гродненская');

#TRUNCATE TABLE `cities`;
INSERT INTO `cities` (`country_id`, `region_id`, `name`) VALUES
(2, 5, 'Апрелевка'),
(2, 5, 'Балашиха'),
(2, 5, 'Белоозёрский'),
(2, 5, 'Егорьевск'),
(2, 5, 'Мытищи'),
(2, 5, 'Домодедово'),
(2, 5, 'Химки'),
(2, 5, 'Клин'),
(2, 4, 'Тихвин'),
(2, 4, 'Мурино'),
(2, 4, 'Выборг'),
(2, 4, 'Луга'),
(2, 4, 'Приморск'),
(5, 14, 'Борисов'),
(5, 14, 'Солигорск'),
(5, 14, 'Слуцк'),
(5, 14, 'Дзержинск');

SELECT `cities`.`name` AS `Город`, `regions`.`name` AS `Область` , `countries`.`name` AS `Страна`
FROM `cities` 
LEFT JOIN `regions` ON `cities`.`region_id` = `regions`.id
LEFT JOIN `countries` ON `cities`.`country_id` = `countries`.id
WHERE `cities`.`name` = 'Балашиха'
;

SELECT `cities`.`name` AS `Город`, `regions`.`name` AS `Область` , `countries`.`name` AS `Страна`
FROM `cities` 
LEFT JOIN `regions` ON `cities`.`region_id` = `regions`.id
LEFT JOIN `countries` ON `cities`.`country_id` = `countries`.id
WHERE `cities`.`region_id` = 
	(SELECT `id` FROM `regions` WHERE `name` = 'Московская' LIMIT 1)
;

/*======================================================================
		Отделы и сотрудники
  ======================================================================*/
CREATE TABLE `departments` (
`id` INT(11) NOT NULL AUTO_INCREMENT,
`name` VARCHAR(50) NOT NULL,
PRIMARY KEY (`id`),
KEY (`name`)
);

INSERT INTO `departments` (`name`) VALUES
('Продаж'),
('Буфет'),
('Бухгалтерия'),
('Охрана')
;

CREATE TABLE `employees` (
`id` INT(11) NOT NULL AUTO_INCREMENT,
`last_name` VARCHAR(45) NOT NULL,
`first_name` VARCHAR(45) NOT NULL,
`job_title` VARCHAR(30) NOT NULL,
`dep_id` INT(11) NOT NULL,
`salary` DECIMAL(9,2),
`dob` DATE,
PRIMARY KEY (`id`),
KEY `dep_id` (`dep_id`),
KEY `last_name` (`last_name`),
CONSTRAINT `fk_employee_departments` FOREIGN KEY  (`dep_id`)
	REFERENCES `departments` (`id`)
		ON UPDATE CASCADE
        ON DELETE RESTRICT
);

INSERT INTO `employees` (`last_name`, `first_name`, `job_title`, `dep_id`, `salary`) VALUES
('Попопв', 'Варлам', 'специалист', 1, 25000.00),
('Тихонов', 'Максим', 'инженер', 1, 35000.00),
('Конева', 'Анна', 'менеджер', 1, 29000.00),
('Пушкин', 'Алексей', 'начальник', 1, 45000.00),
('Сытный', 'Борис', 'повар', 2, 37000.00),
('Лосева', 'Катерина', 'посудомойка', 2, 20000.00),
('Киселёва', 'Антонина', 'кассир', 2, 24500.00),
('Золотова', 'София', 'гл. бухгалтер', 3, 55000.00),
('Сёмина', 'Светлана', 'бухгалтер', 3, 34000.00),
('Мамин-Сибиряк', 'Агата', 'бухгалтер', 3, 32000.00),
('Красов', 'Никита', 'нач. отдела', 4, 45000.00),
('Некрасов', 'Данила', 'дежурный', 4, 28000.00)
;

/* Средняя зарплата (по отделам) */
SELECT `departments`.`name` AS `Отдел`, avg(`salary`) AS `Средняя з/п` FROM `employees`
INNER JOIN `departments` ON `dep_id` = `departments`.`id` 
GROUP BY `dep_id` 
ORDER BY `departments`.`name` ASC;

/* Максимальная зарплата в компании */
SELECT max(`salary`) AS `Максимальная зарплата` FROM `employees`;

/* Сотрудники, получающие максимальную зарплату */
SELECT concat(`first_name`, ' ' , `last_name`) AS `Сотрудник`, `salary` AS `Зарплата`,
`job_title` AS `Должность` FROM `employees`
WHERE `salary` = (SELECT max(`salary`) FROM `employees`);

/* Удалить одного сотрудника с максимальной зарплатой */
/*Error 1093 In MySQL, you can't modify the same table which you use in the SELECT part.
SET optimizer_switch = 'derived_merge=off';*/
DELETE FROM `employees` 
	WHERE `id` = (
		SELECT `id` FROM `employees` 
			WHERE `salary` = (SELECT max(`salary`) FROM `employees`) 
			LIMIT 1
	)
;

/* v2 Error 1093*/
DELETE FROM `employees`
	WHERE `id` = (SELECT `id` FROM `employees` ORDER BY `salary` DESC LIMIT 1) 
;

/* v3 */
DELETE FROM `employees`
	WHERE `id` = (
		SELECT `id` FROM
			(SELECT * FROM `employees` ORDER BY `salary` DESC LIMIT 1)  AS `tmp_emps`)
;

/* Количество сотрудников "во всех отделах" (в компании?) */
SELECT count(*) AS `Число сотрудников в компании` FROM `employees`;
/* По отделам */
SELECT count(*) AS `Число сотрудников в отделе` FROM `employees` GROUP BY `dep_id`;

/* Число сотрудников по отделам и общая зарплата сотрудников в каждом из отделов */
SELECT `departments`.`name` AS `Отдел`, count(*) AS `Число сотрудников`, 
	sum(`salary`) AS `Общая зарплата` FROM `employees` 
INNER JOIN `departments` ON `dep_id` = `departments`.`id`
	GROUP BY `Отдел`;


