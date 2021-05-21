select * from user_likes_songs;

select * from user_likes_songs where songid = 4; 

begin transaction isolation level read committed;

delete from user_likes_songs;

delete from user_likes_songs where userid = 1 and songid  = 4;

rollback;

commit;


select * from user_likes_songs;

select * from user_likes_songs where songid = 4; 

begin transaction isolation level serializable;

delete from user_likes_songs;

delete from user_likes_songs where userid = 1 and songid  = 4;

rollback;

commit;


CREATE USER user_menager WITH PASSWORD 'qwerty';

GRANT INSERT, SELECT, DELETE ON user_likes_songs, user_has_playlist TO user_menager;
GRANT SELECT ON users TO user_menager;

REVOKE ALL PRIVILEGES ON user_likes_songs FROM user_menager;
REVOKE ALL PRIVILEGES ON user_has_playlist FROM user_menager;
REVOKE ALL PRIVILEGES ON users FROM user_menager;

DROP USER user_menager;




CREATE USER artists_menager WITH PASSWORD 'qwertyu';

GRANT INSERT SELECT DELETE ON albums, artists, songs_has_generes, songs TO artists_menager;

REVOKE ALL PRIVILEGES ON albums FROM artists_menager;
REVOKE ALL PRIVILEGES ON artists FROM artists_menager;
REVOKE ALL PRIVILEGES ON songs_has_generes FROM artists_menager;
REVOKE ALL PRIVILEGES ON songs FROM artists_menager;

DROP USER artists_menager;




CREATE USER normal_user;

GRANT SELECT ON artists, albums, song_has_geners, playlists, playlists_has_songs, user_likes_songs, user_has_playlist, plans TO normal_user;

REVOKE ALL PRIVILEGES ON artists, albums, song_has_geners, playlists, playlists_has_songs, user_likes_songs, user_has_playlist, plans FROM normal_user;

DROP USER normal_user;



CREATE USER plan_menager; 

GRANT SELECT, DELETE, INSERT ON "plans" TO plan_menager;

REVOKE ALL PRIVILEGES ON "plans" FROM plan_menager;

DROP USER plan_menager;



CREATE OR REPLACE PROCEDURE like_song(s int, u int)
LANGUAGE plpgsql
AS $$
BEGIN
	IF (SELECT count(songid) FROM user_likes_songs WHERE songid = s AND userid = u) = 0 	THEN
	INSERT INTO user_likes_songs VALUES(s,u);
	RAISE NOTICE 'user liked song succesfully';
	ELSE
	RAISE NOTICE 'user already likes this song'; END IF;
END;
$$;

CALL like_song(1,30);



CREATE OR REPLACE PROCEDURE add_to_playlist(p int, s int)
LANGUAGE plpgsql
AS $$
BEGIN
	IF (SELECT count(songid) FROM playlists_has_songs WHERE songid = s AND playlistid = p) = 0 	THEN
	INSERT INTO playlists_has_songs VALUES(p,s);
	RAISE NOTICE 'song added to playlist';
	ELSE
	RAISE NOTICE 'song is already in playlist'; END IF;
END;
$$;

CALL add_to_playlist(10, 1);

CREATE OR REPLACE PROCEDURE change_plan(u int, p int, d int DEFAULT 0)
LANGUAGE plpgsql
AS $$
BEGIN
	if(d <> 0) THEN 
	UPDATE users SET planid = p WHERE userid = u; 
	RAISE NOTICE 'song added to playlist';

END;
$$;


CREATE OR REPLACE FUNCTION update_plans() RETURNS trigger AS $update_plans$

BEGIN
	IF NEW.premium_days = 0 THEN
	UPDATE users SET planid = 5 WHERE userid = NEW.userid;
	END IF;
	RETURN NEW;
END;
$update_plans$ LANGUAGE plpgsql;

DROP PROCEDURE update_plans;

CREATE TRIGGER premium_days_update_trigger
	AFTER UPDATE OR INSERT OF premium_days ON users
	FOR EACH ROW  
	EXECUTE PROCEDURE update_plans();

SELECT * FROM users;
BEGIN;
UPDATE users SET premium_days = 0 WHERE userid = 2;
ROLLBACK;
	
CREATE VIEW example_weekly AS SELECT song_name FROM 
(
SELECT DISTINCT s.song_name 
FROM songs AS s 
INNER JOIN song_has_geners AS g 
ON s.songid = g.songid 
WHERE 
s.songid NOT IN 
	(
	SELECT songid 
	FROM user_likes_songs 
	WHERE userid = 1
	)
AND 
g.genere IN 
	(
	SELECT genere
	FROM song_has_geners AS shg 
	INNER JOIN user_likes_songs AS uls
	ON shg.songid = uls.songid 
	WHERE userid = 1
	GROUP BY shg.genere
	ORDER BY count(shg.genere) 
	DESC LIMIT 5
	) 
) AS song
ORDER BY random() LIMIT 20; 

CREATE VIEW most_liked_artists AS SELECT a.artist_name,
COUNT(uls.userid) AS likes,
concat((round((COUNT(uls.userid) * 100)/(SELECT count(userid) FROM user_likes_songs)::numeric), 2)::varchar, '%') AS perc
FROM artists AS a 
INNER JOIN albums AS al 
ON a.artistid = al.artist
INNER JOIN songs AS s 
ON al.albumid = s.album 
INNER JOIN user_likes_songs AS uls 
ON uls.songid = s.songid
GROUP BY a.artist_name
ORDER BY COUNT(uls.userid) DESC LIMIT 5;

CREATE VIEW artist_listeners_city AS SELECT c.name, c.country, count(c.cityid) AS enjoyers FROM city AS c 
INNER JOIN users AS u
ON c.cityid = u.cityid
WHERE userid in
(SELECT DISTINCT userid FROM user_likes_songs WHERE songid IN 
(
SELECT s.songid 
FROM songs AS s
INNER JOIN albums AS alb
ON s.album = alb.albumid 
INNER JOIN artists AS a
ON a.artistid = alb.artist WHERE a.artistid = 1
))
GROUP BY c.name, c.country
ORDER BY enjoyers DESC LIMIT 3;

CREATE VIEW artist_main_generes AS SELECT genere 
FROM song_has_geners
WHERE songid IN 
(
SELECT s.songid FROM songs AS s
INNER JOIN albums a2 
ON a2.albumid = s.album
INNER JOIN artists a3 
ON a3.artistid = a2.artist
WHERE a3.artistid = 3
)
GROUP BY genere
ORDER BY count(genere) LIMIT 3;

CREATE VIEW premium_users_percentage AS SELECT 
Round(((
SELECT count(userid) FROM users WHERE planid <> 5)/
count(userid)::NUMERIC) * 100, 1) AS premium_percentage 
FROM users;





BEGIN ISOLATION LEVEL SERIALIZABLE;

DELETE FROM user_likes_songs WHERE songid IN (SELECT songid FROM songs WHERE album = 9);

DELETE FROM playlists_has_songs WHERE songid IN (SELECT songid FROM songs WHERE album = 9);

DELETE FROM song_has_geners WHERE songid IN (SELECT songid FROM songs WHERE album = 9);

SAVEPOINT deleted_branches;

DELETE FROM songs WHERE album = 9;

DELETE FROM albums WHERE albumid = 9;

SAVEPOINT deleted_album;

TRUNCATE TABLE user_has_playlist;
TRUNCATE TABLE playlists_has_songs;
TRUNCATE TABLE playlists_for_users;
TRUNCATE TABLE playlists CASCADE;

SAVEPOINT clear_playlists;

INSERT INTO city (cityid ,"name", country) VALUES(11,'Szczebrzeszyn', 'Scotland');
INSERT INTO users (userid, username, "password", planid, cityid, premium_days) VALUES(32,'ggadsf','asdgasdg',5,11,0);

ROLLBACK TO deleted_branches;
ROLLBACK TO deleted_album;
ROLLBACK TO clear_playlists;

ROLLBACK;

COMMIT;

SELECT * FROM song_has_geners;
SELECT * FROM playlists_has_songs;
SELECT * FROM song_has_geners;
SELECT * FROM songs;
SELECT * FROM albums;

SELECT * FROM user_likes_songs;
SELECT * FROM playlists_has_songs;
SELECT * FROM playlists_for_users;
SELECT * FROM playlists;

SELECT * FROM city;
SELECT * FROM users;







