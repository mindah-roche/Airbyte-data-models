# Quick Reference Guide

## Common Analysis Queries

### 1. What tracks are listened to most over time?

#### Most played tracks (all time)
```sql
SELECT 
    track_name,
    artist_name,
    play_count,
    total_listening_minutes,
    play_count_rank
FROM mart_track_popularity
ORDER BY play_count DESC
LIMIT 20;
```

#### Most played tracks by month
```sql
SELECT 
    DATE_TRUNC('month', played_at) as month,
    track_name,
    artist_name,
    COUNT(*) as plays_this_month
FROM fct_track_plays
WHERE played_at >= DATEADD('month', -6, CURRENT_DATE())
GROUP BY month, track_name, artist_name
ORDER BY month DESC, plays_this_month DESC;
```

#### Track listening over time (time series)
```sql
SELECT 
    played_date,
    track_name,
    artist_name,
    COUNT(*) as daily_plays
FROM fct_track_plays
WHERE track_id = 'your_track_id'
GROUP BY played_date, track_name, artist_name
ORDER BY played_date;
```

### 2. Which artists drive the most listening time?

#### Top artists by listening time
```sql
SELECT 
    artist_name,
    total_listening_hours,
    total_plays,
    unique_tracks_played,
    pct_of_total_listening,
    listening_time_rank
FROM mart_artist_listening_time
ORDER BY total_listening_hours DESC
LIMIT 20;
```

#### Artist listening time by month
```sql
SELECT 
    DATE_TRUNC('month', played_at) as month,
    artist_name,
    SUM(track_duration_minutes) / 60.0 as listening_hours,
    COUNT(*) as plays
FROM fct_track_plays
GROUP BY month, artist_name
ORDER BY month DESC, listening_hours DESC;
```

### 3. How does listening behavior trend daily and weekly?

#### Daily listening trends (last 30 days)
```sql
SELECT 
    played_date,
    total_plays,
    total_listening_minutes,
    unique_tracks,
    unique_artists,
    plays_7day_avg,
    CASE 
        WHEN total_plays > plays_7day_avg THEN 'Above Average'
        ELSE 'Below Average'
    END as vs_average
FROM mart_listening_trends
WHERE played_date >= DATEADD('day', -30, CURRENT_DATE())
ORDER BY played_date DESC;
```

#### Listening by day of week
```sql
SELECT 
    CASE played_day_of_week
        WHEN 1 THEN 'Sunday'
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
        WHEN 7 THEN 'Saturday'
    END as day_name,
    AVG(total_plays) as avg_plays,
    AVG(total_listening_minutes) as avg_listening_minutes
FROM fct_track_plays
GROUP BY played_day_of_week
ORDER BY played_day_of_week;
```

#### Listening by hour of day
```sql
SELECT 
    played_hour,
    COUNT(*) as total_plays,
    SUM(track_duration_minutes) as total_minutes,
    COUNT(DISTINCT played_date) as active_days,
    COUNT(*) / COUNT(DISTINCT played_date) as avg_plays_per_day
FROM fct_track_plays
GROUP BY played_hour
ORDER BY played_hour;
```

#### Weekly trends
```sql
SELECT 
    played_year,
    played_week,
    MIN(played_date) as week_start,
    MAX(played_date) as week_end,
    SUM(total_plays) as weekly_plays,
    SUM(total_listening_minutes) / 60.0 as weekly_hours,
    AVG(unique_tracks) as avg_daily_unique_tracks
FROM mart_listening_trends
GROUP BY played_year, played_week
ORDER BY played_year DESC, played_week DESC
LIMIT 12;
```

### 4. How do audio features correlate with popularity?

#### Average play count by audio feature buckets
```sql
SELECT 
    danceability_bucket,
    energy_bucket,
    valence_bucket,
    COUNT(*) as track_count,
    AVG(play_count) as avg_plays,
    AVG(track_popularity) as avg_spotify_popularity
FROM mart_track_popularity
WHERE danceability IS NOT NULL
GROUP BY danceability_bucket, energy_bucket, valence_bucket
ORDER BY avg_plays DESC;
```

#### Correlation between danceability and plays
```sql
SELECT 
    ROUND(danceability, 1) as danceability_rounded,
    COUNT(*) as track_count,
    AVG(play_count) as avg_plays,
    SUM(play_count) as total_plays
FROM mart_track_popularity
WHERE danceability IS NOT NULL
GROUP BY danceability_rounded
ORDER BY danceability_rounded;
```

#### Most played tracks by audio feature profile
```sql
-- High energy, high danceability tracks
SELECT 
    track_name,
    artist_name,
    play_count,
    danceability,
    energy,
    valence
FROM mart_track_popularity
WHERE danceability > 0.7 
  AND energy > 0.7
ORDER BY play_count DESC
LIMIT 10;

-- Acoustic, low energy tracks
SELECT 
    track_name,
    artist_name,
    play_count,
    acousticness,
    energy
FROM mart_track_popularity
WHERE acousticness > 0.7 
  AND energy < 0.5
ORDER BY play_count DESC
LIMIT 10;
```

#### Feature correlation matrix (requires statistical functions)
```sql
SELECT 
    CORR(danceability, play_count) as danceability_correlation,
    CORR(energy, play_count) as energy_correlation,
    CORR(valence, play_count) as valence_correlation,
    CORR(acousticness, play_count) as acousticness_correlation,
    CORR(tempo, play_count) as tempo_correlation,
    CORR(track_popularity, play_count) as popularity_correlation
FROM mart_track_popularity
WHERE danceability IS NOT NULL;
```

## Advanced Analysis

### Genre analysis (if genres available)
```sql
SELECT 
    a.genres,
    COUNT(DISTINCT fp.track_id) as unique_tracks,
    SUM(fp.track_duration_minutes) / 60.0 as total_hours,
    COUNT(*) as total_plays
FROM fct_track_plays fp
JOIN dim_artists a ON fp.artist_id = a.artist_id
WHERE a.genres IS NOT NULL
GROUP BY a.genres
ORDER BY total_hours DESC;
```

### Context analysis (playlist vs album vs artist)
```sql
SELECT 
    context_type,
    COUNT(*) as plays,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () as pct_of_plays,
    SUM(track_duration_minutes) / 60.0 as listening_hours
FROM fct_track_plays
WHERE context_type IS NOT NULL
GROUP BY context_type
ORDER BY plays DESC;
```

### Album release date analysis
```sql
SELECT 
    EXTRACT(YEAR FROM album_release_date) as release_year,
    COUNT(DISTINCT track_id) as unique_tracks,
    SUM(play_count) as total_plays,
    AVG(play_count) as avg_plays_per_track
FROM mart_track_popularity
WHERE album_release_date IS NOT NULL
  AND album_release_date >= '2020-01-01'
GROUP BY release_year
ORDER BY release_year DESC;
```

### Discovery rate (new tracks per week)
```sql
SELECT 
    played_year,
    played_week,
    COUNT(DISTINCT track_id) as unique_tracks,
    COUNT(DISTINCT CASE 
        WHEN first_played_at >= DATE_TRUNC('week', played_date) 
        THEN track_id 
    END) as new_tracks_this_week
FROM fct_track_plays fp
JOIN dim_tracks t ON fp.track_id = t.track_id
GROUP BY played_year, played_week
ORDER BY played_year DESC, played_week DESC
LIMIT 12;
```

## Dashboard Metrics

### Key Performance Indicators (KPIs)
```sql
WITH current_week AS (
    SELECT 
        SUM(total_plays) as plays,
        SUM(total_listening_minutes) as minutes,
        AVG(unique_tracks) as unique_tracks,
        AVG(unique_artists) as unique_artists
    FROM mart_listening_trends
    WHERE played_date >= DATE_TRUNC('week', CURRENT_DATE())
),
previous_week AS (
    SELECT 
        SUM(total_plays) as plays,
        SUM(total_listening_minutes) as minutes,
        AVG(unique_tracks) as unique_tracks,
        AVG(unique_artists) as unique_artists
    FROM mart_listening_trends
    WHERE played_date >= DATE_TRUNC('week', DATEADD('week', -1, CURRENT_DATE()))
      AND played_date < DATE_TRUNC('week', CURRENT_DATE())
)
SELECT 
    c.plays as current_week_plays,
    p.plays as previous_week_plays,
    (c.plays - p.plays) * 100.0 / p.plays as plays_change_pct,
    c.minutes / 60.0 as current_week_hours,
    p.minutes / 60.0 as previous_week_hours,
    (c.minutes - p.minutes) * 100.0 / p.minutes as hours_change_pct
FROM current_week c
CROSS JOIN previous_week p;
```
