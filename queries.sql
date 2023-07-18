-- Get an output of tracks
SELECT
	t.track_name,
	a.artist_name,
	al.album_name,
	t.play_count,
	t.last_played,
	t.date_added,
	t.apple_music,
	t.genre,
	t.playlist_only,
	t.skip_count
FROM
	track t
	JOIN artist a ON t.artist_id = a.artist_id
	JOIN album al ON al.album_id = t.album_id
WHERE
	last_played IS NOT NULL
	OR NOT playlist_only
ORDER BY
	last_played DESC;

-- Get an aggregated view of albums
SELECT
	al.album_name,
	a.artist_name,
	MAX(last_played) AS most_recent_play,
	COUNT(track_id) AS no_tracks,
	SUM(play_count) AS total_plays,
	MIN(date_added) AS track_first_added
FROM
	track t
	JOIN artist a ON t.artist_id = a.artist_id
	JOIN album al ON al.album_id = t.album_id
WHERE
	(last_played IS NOT NULL
	OR NOT playlist_only)
--	AND artist_name ILIKE 'name'
GROUP BY
	al.album_name,
	a.artist_name
ORDER BY
	total_plays DESC