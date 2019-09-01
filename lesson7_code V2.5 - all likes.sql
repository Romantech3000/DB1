#
# V 2.5 (this version) Added mutual likes calculation that takes into account
# liked photos and comments in addition to liked user profiles.
# V 2.0  Edited to follow the requirements of task 3 from the very beginning
# All table alterations are edited out and moved to tables' creation code
# As for given, received and mutual likes, only user profile likes are taken into account
# other content types are ignored in this version

#
# Creatind the data structures (schema and tables) 
#
CREATE SCHEMA `social7` CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `social7`;
CREATE TABLE `users` (
	`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `first_name` VARCHAR(40) NOT NULL,
    `last_name` VARCHAR(40) NOT NULL,
    `login` VARCHAR(25) NOT NULL,
    `email` VARCHAR(35) NOT NULL,
    `phone` VARCHAR(20) NULL DEFAULT NULL,
   # `likes_given` INT NOT NULL DEFAULT 0,
   # `likes_received` INT NOT NULL DEFAULT 0,
    INDEX (`login`),
    INDEX `full_name` (`last_name`, `first_name`)
)
ENGINE = InnoDB;

#
# Filling in some test data
#
INSERT INTO `users` (`first_name`, `last_name`, `login`, `email`, `phone`) VALUES
	('John', 'Doe', 'joedoe', 'joe-doe@mail.com', NULL),
    ('Ann', 'Smith', 'annies', 'a.smith@mail.com', '+01235899'),
    ('Carl', 'Cox', 'sailor1985', 'sailor@mail.com', NULL),
    ('Bill', 'Smozzy', 'billy-boy', 'apple@mail.com', '+3904875527'),
    ('Mary', 'Fitzerald', 'lambie1990', 'mary-ann@mail.com', NULL)
;
/*
SET FOREIGN_KEY_CHECKS = 0; 
TRUNCATE TABLE `users`; 
SET FOREIGN_KEY_CHECKS = 1;
*/
SELECT * FROM `users`;

#
# Content types table for task 3
#
CREATE TABLE `content_type` (
	`id` TINYINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(20) NOT NULL UNIQUE
) ENGINE = InnoDB
;

# 1 - user profile 2 - photograph, 3 - commentary to a photograph
# content types that can be liked 
INSERT INTO `content_type` (`name`) VALUES ('user'), ('photo'), ('comment');

#
# Likes for users
#
CREATE TABLE `likes` (
	`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `from_user` INT NOT NULL,
    # to distinguish between likes for users, comments and photos (for task 3)
    `target_type` TINYINT NOT NULL COMMENT '1 - user, 2 - photo, 3 - comment',
    `target_id` INT NOT NULL COMMENT 'id of a user, photo or commentary',

	INDEX (`from_user`),
    INDEX (`target_type`),
    INDEX (`target_id`),
    CONSTRAINT `fk_likes_from__users` FOREIGN KEY (`from_user`) REFERENCES `users` (`id`)
		ON DELETE RESTRICT
        ON UPDATE CASCADE,
# left the following code as a reminder that the original likes table contained separate column 
# for id's of users receiving the likes. that had some pros like easier finding of mutual likes
# for users, but since task 1 only required to count user profile likes, I just ignore likes for
# photos and comments in given/received/mutual likes count
#	CONSTRAINT `likes_users_fk_to` FOREIGN KEY (`to_user`) REFERENCES `users` (`id`)
#		ON DELETE RESTRICT
#        ON UPDATE CASCADE,
	CONSTRAINT `fk_likes__content_type_id`
		FOREIGN KEY (`target_type`)
        REFERENCES `content_type` (`id`)
        ON DELETE RESTRICT
        ON UPDATE CASCADE                
#
# con't use the target/content id constraint bacause there's no unified content table
# I could create such a table, but then I'd just move the potential problem deeper into structure
) 
ENGINE = InnoDB;

# some likes for users only (content_type = DEFAULT 1)
INSERT INTO `likes` (`from_user`, `target_type`, `target_id`) VALUES 
	(1,1,3), (1,1,3), (1,1,3), (2,1,1), (2,1,3), (3,1,1), (3,1,1), (3,1,1), (3,1,1), 
    (1,1,3), (1,1,3), (2,1,3), (2,1,3), (2,1,3), (2,1,3), (1,1,4), (1,1,5), (1,1,5),
    (4,1,1), (4,1,1), (1,1,4), (4,1,1), (4,1,3), (4,1,3)
;
#TRUNCATE TABLE `likes`;
SELECT * FROM `likes`;

# ======================================================================================
#   JOIN approach. No additional fields, but much slower select with counters and joins
# ======================================================================================
# function returning the sum of all mutual likes for the user of interest
# Takes in account only likes for user profiles (target_type = 1) as Task 1 requires
DROP FUNCTION IF EXISTS spGetMutualLikes;
DELIMITER ;;
CREATE FUNCTION spGetMutualLikes(uid INT) RETURNS INT
NOT DETERMINISTIC
READS SQL DATA
BEGIN
	DECLARE likes_count INT;

	SELECT SUM(`mutuals`) INTO likes_count FROM 
	(
		SELECT LEAST(`t1`.`likes_from_user`,`t2`.`likes_to_user`) AS `mutuals`
		/*``t1`.`to_user` AS `user2`, t1`.`likes_from_user` AS `u1_to_u2`, `t2`.`likes_to_user` AS `u2_to_u1`*/
		FROM 
			# how many likes our user has given to every other user
			(SELECT COUNT(*) AS `likes_from_user`, `target_id` FROM `likes` 
				WHERE `target_type` = 1 AND `from_user` = uid GROUP BY `target_id`) AS `t1`
		INNER JOIN 
			# how many likes each of those users has given to our user
			(SELECT COUNT(*) AS `likes_to_user`, `from_user` FROM `likes` 
				WHERE `target_type` = 1 AND `target_id` = uid GROUP BY `from_user`) AS `t2`
			ON `t1`.`target_id` = `t2`.`from_user`
	) AS `t`;

    RETURN IFNULL(likes_count, 0);
END;;
DELIMITER ;
# testing the mutual likes function
SELECT spGetMutualLikes(1), spGetMutualLikes(2), spGetMutualLikes(3), spGetMutualLikes(4);

# getting a table with conditional target_user column
# to_user - id of a user who receives the like. 
# it's assigned one of the following: 1. target_id if like target is liked user's profile
# 2. photo.id if like target is a photograph
# 3. photo_comment.id if a comment to a photo was liked
SELECT l.id AS like_id, l.from_user,
		#IF (l.target_type > 2, c.user_id, p.user_id) AS to_user
        ( CASE l.target_type 
			WHEN 1 THEN l.target_id 
			WHEN 2 THEN p.user_id
            WHEN 3 THEN c.user_id
		  END) AS to_user,
		l.target_type
	FROM `likes` l
		LEFT JOIN `photo` p
			ON p.id = l.target_id AND l.target_type = 2
        LEFT JOIN `photo_comment` c
			ON c.id = l.target_id AND l.target_type = 3;


# ========================================================================================
#   Same as spGetMutualLikes, but counts like for all types of content as mutual likes
# Includes another SELECT to find out who's the author of the given piece of liked content
# =========================================================================================
# !!!! With all the data manipulation involved, it'd probably be more efficient to store author_id
# for all kind of content in the likes table and update it with triggers set in the content tables
#
DROP FUNCTION IF EXISTS spGetMutualLikesAll;
DELIMITER ;;
CREATE FUNCTION spGetMutualLikesAll(uid INT) RETURNS INT
NOT DETERMINISTIC
READS SQL DATA
BEGIN
	DECLARE likes_count INT;

	# create a table where target user is specified for each like (target_user column)
	/*
    DROP TEMPORARY TABLE IF EXISTS `tmp_likes`;
	CREATE TEMPORARY TABLE `tmp_likes` SELECT l.id, l.from_user,
        ( CASE l.target_type 
			WHEN 1 THEN l.target_id 
			WHEN 2 THEN p.user_id
            WHEN 3 THEN c.user_id
		  END) AS target_user
	FROM `likes` l
		LEFT JOIN `photo` p
			ON p.id = l.target_id AND l.target_type = 2
        LEFT JOIN `photo_comment` c
			ON c.id = l.target_id AND l.target_type = 3;
	*/
	# Tried to store the result of the select in a temporary table
    # and use the table to find out mutual likes via joining the table with itself
    # but differently grouped.
    # Got ERROR 1137: Can't reopen table when joining a temporary table
    # Reason: https://dev.mysql.com/doc/refman/8.0/en/temporary-table-problems.html
    # "You cannot refer to a TEMPORARY table more than once in the same query. "

	# WORKAROUND (seems to be one) use of a common table expression (CTE). Working for versions 8.0+
    # For prior versions people seem to use hacks like: creating non-temporary tables,
    # keep the identical sub-queries behind temporary table, duplicate the temporary table
    
    WITH tmp_likes AS 
    (SELECT l.id, l.from_user,
        ( CASE l.target_type 
			WHEN 1 THEN l.target_id 
			WHEN 2 THEN p.user_id
            WHEN 3 THEN c.user_id
		  END) AS target_user
	FROM `likes` l
		LEFT JOIN `photo` p
			ON p.id = l.target_id AND l.target_type = 2
        LEFT JOIN `photo_comment` c
			ON c.id = l.target_id AND l.target_type = 3
	)
	SELECT SUM(`mutuals`) INTO likes_count FROM 
	(
		SELECT LEAST(`t1`.`likes_from_user`,`t2`.`likes_to_user`) AS `mutuals`
		FROM 
			# how many likes the user has given to every other user
			(SELECT COUNT(*) AS `likes_from_user`, `target_user` FROM `tmp_likes`
				WHERE `from_user` = uid GROUP BY `target_user`) AS `t1`
		INNER JOIN 
			# how many likes each of those users has given to our user
			(SELECT COUNT(*) AS `likes_to_user`, `from_user` FROM `tmp_likes`
				WHERE `target_user` = uid GROUP BY `from_user`) AS `t2`
			ON `t1`.`target_user` = `t2`.`from_user`
	) AS `t`;
    

	DROP TEMPORARY TABLE IF EXISTS `tmp_likes`;

    RETURN IFNULL(likes_count, 0);
END;;
DELIMITER ;

# testing the mutual likes function
SELECT spGetMutualLikesAll(1), spGetMutualLikesAll(2), spGetMutualLikesAll(3), spGetMutualLikesAll(4);

#
# get all user data required in the task
#
# received and given likes are counted only for user profile likes, not the other content types
SET @userId = 1;
SELECT `id`, `first_name`, `likes_given`, `likes_received`, spGetMutualLikes(@userId) AS `mutual_likes_total`
FROM (SELECT * FROM `users` WHERE `users`.`id` = @userId) AS `user1`
	LEFT JOIN ( # links given
		SELECT `from_user`, COUNT(*) AS `likes_given` FROM `likes` l WHERE l.`target_type` = 1 AND l.`from_user` = @userId 
        ) AS `fu` ON `user1`.`id` = `fu`.`from_user`
	LEFT JOIN ( # likes received
		SELECT `target_id`, COUNT(*) AS `likes_received` FROM `likes` l WHERE l.`target_type` = 1 AND l.`target_id` = @userId 
    ) AS `tu` ON `user1`.`id` = `tu`.`target_id`
;

#
# users that liked user A and user B, but not user C
# for user profiles only, not photos or comments
#
SET @uidA = 1;
SET @uidB = 3;
SET @uidC = 4;

SELECT DISTINCT `t_a`.`from_user` AS `user_ab_not_c` FROM
	(SELECT `from_user` FROM `likes` WHERE `target_id` = @uidA) `t_a`
INNER JOIN
	(SELECT DISTINCT `from_user` FROM `likes` WHERE `target_id` = @uidB) `t_b`
	ON `t_a`.`from_user` = `t_b`.`from_user`
INNER JOIN
	(SELECT DISTINCT `from_user` FROM `likes` WHERE `target_id` != @uidC) `t_not_c`
	ON `t_a`.`from_user` = `t_not_c`.`from_user`
;



# =====================================================
# 			Photographs and commentaries (for Task 3)
# =====================================================
# DROP TABLE `photo`;
CREATE TABLE `photo` (
	`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `title` VARCHAR(64) NOT NULL DEFAULT 'no name',
    `file` VARCHAR(64) NOT NULL,
    INDEX (`user_id`),
    CONSTRAINT `fk_photo__users`
		FOREIGN KEY (`user_id`)
        REFERENCES `users` (`id`)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE = InnoDB;

INSERT INTO `photo` (`user_id`, `title`, `file`) VALUES
	(1, 'My cat 1', 'image001.jpg'), (1, 'My cat 2', 'image002.jpg'), (1, 'My cat 3', 'image003.jpg'),
    (3, 'My dog 1', 'image004.jpg'), (3, 'My dog 2', 'image005.jpg'),(3, 'My dog 3', 'image006.jpg'),
    (4, 'My fox 1', 'image007.jpg'), (3, 'My fox 2', 'image008.jpg'),(3, 'My fox 3', 'image009.jpg'),
    (4, 'My fox eats chicken', 'image010.jpg'), (3, 'My fox sleeping', 'image011.jpg'),
    (2, 'My bakery', 'image012.jpg'), (5, 'My lamb sleeping', 'image013.jpg'),
    (5, 'Lambie gets it', 'image014.jpg'), (5, 'My lamb eating cheese', 'image0151.jpg')
;

SELECT * FROM `photo`;

CREATE TABLE `photo_comment` (
	`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `photo_id` INT NOT NULL,
    `title` VARCHAR(64) NOT NULL DEFAULT '',
    `text` VARCHAR(300) NOT NULL,
    INDEX (`user_id`),
    INDEX (`photo_id`),
    CONSTRAINT `fk_photo_comment__user`
		FOREIGN KEY (`user_id`)
        REFERENCES `users` (`id`)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
	CONSTRAINT `fk_photo_comment__photo`
		FOREIGN KEY (`photo_id`) 
        REFERENCES `photo` (`id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE = InnoDB;

#
# Some commentaries for photographs
#
INSERT INTO `photo_comment` (`user_id`, `photo_id`,`title`, `text`) VALUES
	(4, 1, 'Nice photo', 'The cat looks very nice'),
    (4, 2, 'Nice photo', 'What a phat cat!'),
    (4, 3, 'Nice photo', 'The cat looks very nice'),
	(4, 4, 'Amazing photo', 'The dog looks very nice'),
    (2, 1, 'Cuoootey', 'The best looking cat. Liked'),
    (2, 2, 'Nice photo', 'The cat looks very nice'),
    (1, 12, 'Nice place!', 'I\'ll be visiting soom'),
    (1, 5, 'Cool photo', 'Remonds me of home')
;

#
# some of the photos and
# some of the commentaries for the photograps were liked
#
INSERT INTO `likes` (`from_user`, `target_type`, `target_id`) VALUES 
	(4, 2, 3), (4, 2, 3), (4, 2, 12), (4, 2, 1), (2, 2, 3), (3, 2, 10), (3, 2, 12), 
    (3, 3, 1), (3, 3, 2), (3, 3, 4), (3, 3, 8)
;


#
# limit user to giving only one like per entity. It seems it can't really be prevented
# without throwing an error
#
DELIMITER ;;
CREATE TRIGGER `before_insert_like` BEFORE INSERT ON `likes`
FOR EACH ROW
BEGIN
	IF (
		SELECT COUNT(*) FROM `likes` 
			WHERE `from_user` = New.`from_user` AND `target_id` = New.`to_user`
				AND New.`target_type` = `target_type`
	) > 0
    THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'an attempt to insert a duplicate like';
	END IF;
END;
;;
DELIMITER ;

#
# number of likes for a photo with a given Id
# 
SET @type_id = 2;
SET @photo_id = 12;
SELECT COUNT(*) FROM `likes` WHERE `target_type` = @type_id AND `target_id` = @photo_id;

#
# list of the users who liked the photo
#
SELECT CONCAT(`first_name`, ' ' ,`last_name`) AS `people who liked photo` FROM 
	`users`
INNER JOIN
	(SELECT * FROM `likes` WHERE `target_type` = @type_id AND `target_id` = @photo_id) t
    ON `users`.`id` = `t`.`from_user`
;


# remove the like
DELETE FROM `likes` WHERE `id` = 11;

#
# Main homework tasks. Consider moving to a separate plain text file!
#
#create a user and give the user privileges on all tables of the specified database
CREATE USER 'user1'@'localhost' IDENTIFIED WITH mysql_native_password BY 'userPASS742';
GRANT ALL PRIVILEGES ON `places`.* TO 'user1'@'localhost';

# make a total db backup (including the schema creation, routines and triggers)
mysqldump -u basyo -p --routines --databases places > /var/backup/sql_bu_`date '+%Y-%m-%d'`.sql
mysql -u basyo -p < /var/backup/sql_bu_2019-08-01.sql


# ==============================================================================================
# more RL-like approach using triggers and additional fields to store all data related to a user
#  setting up additional fields in `users` table and adding a triggers for `likes` table
#  slower insert, and more storage space required, but much faster select
# ==============================================================================================
/*
ALTER TABLE `users` 
	ADD COLUMN `likes_in` INT NOT NULL DEFAULT 0,
	ADD COLUMN `likes_out` INT NOT NULL DEFAULT 0
;
#and updating the counters with a trigger
DELIMITER ;;
CREATE TRIGGER `likeAdded` AFTER INSERT ON `likes` FOR EACH ROW
BEGIN
	UPDATE `users` SET `likes_in` = `likes_in` + 1 WHERE `users`.`id` = NEW.to_user;
    UPDATE `users` SET `likes_out` = `likes_out` + 1 WHERE `users`.`id` = NEW.from_user;
END;;
DELIMITER ;

DELIMITER ;;
CREATE TRIGGER `likeAdded` AFTER DELETE ON `likes` FOR EACH ROW
BEGIN
	UPDATE `users` SET `likes_in` = `likes_in` - 1 WHERE `users`.`id` = NEW.to_user;
    UPDATE `users` SET `likes_out` = `likes_out` - 1 WHERE `users`.`id` = NEW.from_user;
END;;
DELIMITER ;
*/
