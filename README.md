# Smarter Playlists

Smarter Playlists lets you explore your music data by exporting your Apple Music library to a DB.

This repo consists of two separate Python scripts. One to move data from Music.app to Postgres and the other to go back the other way.

## Import to Postgres

To import your music data to a local postgres database you just need to follow a few simple steps and then run the `import-to-postgres.py` script.

### Prerequisites
* Python 3.7+
* [python3-psycopg2](http://initd.org/psycopg/)
* Postgres running locally
* An export of your Music.app library (File -> Library -> Export Library...) as an XML file to use as an import for this script
* Basic SQL knowledge to create a playlist of your liking

```bash
python3 ./import-to-postgres.py --library "~/{path to library export}" --db "music" --port 5432 --schema "public" --user "postgres" --pass "postgres"
```

Once the script has successfully run, you should have `artist`, `album` and `track` tables in your choosen schema.

The script can be re-run as many time as desired and simply updates the existing tables with any new information.

## Export to Playlist

### Create a View

To later export a view or table from your postgres music database you simply run the other script, named `export-to-playlist.py`.
This can produce an M3U playlist file that can be automatically imported to Music.app. 

For example, you might create a view such as the following to create a playlist for a month of the year
```sql
CREATE OR REPLACE VIEW jan_2019 AS
 SELECT playlist_tracks.itunes_id,
        ROW_NUMBER() OVER (ORDER BY playlist_tracks.count DESC) AS row_number,
        playlist_tracks.count,
        playlist_tracks.track_name
   FROM (SELECT play.track_id,
                track.itunes_id,
                track.track_name,
                COUNT(*) AS count,
                ROW_NUMBER() OVER (PARTITION BY track.album_id ORDER BY (COUNT(*)) DESC) AS album_rows,
                ROW_NUMBER() OVER (PARTITION BY track.artist_id ORDER BY (COUNT(*)) DESC) AS artist_rows
           FROM play
           JOIN track USING (track_id)
           JOIN artist USING (artist_id)
           JOIN album USING (album_id, artist_id)
          WHERE DATE_PART('month'::text, play.played_at) = '1':: DOUBLE PRECISION
            AND DATE_PART('year'::text, play.played_at) = '2019':: DOUBLE PRECISION
          GROUP BY play.track_id, track.track_name, track.itunes_id, track.album_id, track.artist_id) AS playlist_tracks
  WHERE playlist_tracks.album_rows <= 2 
    AND playlist_tracks.artist_rows <= 5 
    AND playlist_tracks.count > 1
  GROUP BY playlist_tracks.track_id, playlist_tracks.track_name, playlist_tracks.itunes_id, playlist_tracks.count
  ORDER BY playlist_tracks.count DESC
  LIMIT 50;
```

### M3U Format

To export a pre-made SQL view like the one above as an M3U playlist you can run the export script without the format argument (M3U is now the default)
```bash
python3 ./export-to-playlist.py -name "January 2019" -view "jan_2019" --library "~/{path to library export}" --db "music" --port 5432 --schema "public" --user "postgres" --pass "postgres"
```

You can also use the bash script `update_playlist.sh` to auto import it into iTunes for you.
```bash
/bin/sh /Users/Stephan5/Development/smarter-playlists/update_playlist.sh "January 2019" jan_2019
 
```

### XML Format
To export a view to an XML playlist, the export script needs be run with the `--format` argument.

```bash
python3 ./export-to-playlist.py --format XML -name "January 2019" -view "jan_2019" --library "~/{path to library export}" --db "music" --port 5432 --schema "public" --user "postgres" --pass "postgres"
```

This would output an XML file labeled `January 2019.xml` which can be imported into Music.app using File > Library > Import Playlist... 

## Acknowledgements
These scripts borrow heavily from [itunes-to-sql](https://github.com/drien/itunes-to-sql) and [swinsian2itlxml](https://github.com/mhite/swinsian2itlxml) for inspiration. 
