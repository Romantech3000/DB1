/*======================================================================
		Города, области и страны
  ======================================================================*/

CREATE SCHEMA IF NOT EXISTS `db_lesson4` DEFAULT CHAR SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE `db_lesson4`;

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
('Попов', 'Варлам', 'специалист', 1, 25000.00),
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

CREATE TABLE `salary` (
`id` INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
`emp_id` INT(11) NOT NULL,
`payment` DECIMAL(10,2) NOT NULL DEFAULT 0,
KEY `emp_id` (`emp_id`),
CONSTRAINT `fk_salary_employees` FOREIGN KEY (`emp_id`)
	REFERENCES `employees` (`id`)
		ON DELETE CASCADE
        ON UPDATE CASCADE
);