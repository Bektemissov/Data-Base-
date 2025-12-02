DROP TABLE IF EXISTS watch_history CASCADE;
DROP TABLE IF EXISTS videos CASCADE;
DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE users(
    user_id INT PRIMARY KEY,
    username VARCHAR(50),
    email VARCHAR(100),
    subscription_type VARCHAR(20),
    country VARCHAR(50)
);

CREATE TABLE videos (
    video_id INT PRIMARY KEY ,
    title VARCHAR(200),
    genre VARCHAR(50),
    release_year INT,
    duration_minutes INT,
    rating DECIMAL(3,1)
);

CREATE TABLE watch_history (
    watch_id INT PRIMARY KEY ,
    user_id INT,
    video_id INT,
    watch_date TIMESTAMP,
    watch_duration_minutes INT,
    completed BOOLEAN,
FOREIGN KEY (user_id) REFERENCES users(user_id),
FOREIGN KEY (video_id) REFERENCES videos(video_id)

--task 1

SELECT v.title, w.watch_date, w.completed
FROM watch_history w
JOIN videos v ON w.video_id = v.video_id
WHERE w.user_id = 12345
ORDER BY w.watch_date DESC;

CREATE INDEX watch_history_user_date_idx
ON watch_history(user_id, watch_date DESC);

-- Answer Task 1: multicolumn index (user_id, watch_date)

--task 2

CREATE INDEX videos_title_search_idx
ON videos(LOWER(TRIM(title)));

SELECT video_id,
       title,
       ...

--task 3

--question a - redundant index = wh_user_idx

--question b-
DROP INDEX IF EXISTS wh_user_idx;


--task 4
CREATE INDEX watch_history_completed_idx
ON watch_history(user_id, watch_date)
WHERE completed = TRUE;

--answer - smaller index and faster queries,
