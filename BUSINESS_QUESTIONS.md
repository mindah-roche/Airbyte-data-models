# Business Questions & Model Mapping

This document maps each business question to the specific data models and queries needed to answer them.

---

## 1. What tracks are listened to most over time?

### Models to Use
- **Primary**: `mart_track_popularity`
- **Alternative**: `fct_track_plays` (for granular analysis)
- **Supporting**: `dim_tracks`

### Key Metrics Available
- `play_count` - Total number of plays per track
- `play_count_rank` - Ranking by play count
- `first_played_at` / `last_played_at` - Time range
- `pct_of_total_plays` - Share of total listening

### Example Query
```sql
SELECT 
    track_name,
    artist_name,
    play_count,
    play_count_rank,
    total_listening_minutes
FROM mart_track_popularity
ORDER BY play_count DESC
LIMIT 10;
```

### Time-Series Analysis
```sql
SELECT 
    played_date,
    track_name,
    COUNT(*) as daily_plays
FROM fct_track_plays
WHERE track_id = 'your_track_id'
GROUP BY played_date, track_name
ORDER BY played_date;
```

---

## 2. Which artists drive the most listening time?

### Models to Use
- **Primary**: `mart_artist_listening_time`
- **Supporting**: `dim_artists`

### Key Metrics Available
- `total_listening_minutes` / `total_listening_hours` - Absolute listening time
- `listening_time_rank` - Ranking by listening time
- `pct_of_total_listening` - Share of total listening time
- `total_plays` - Total play count
- `unique_tracks_played` - Track variety

### Example Query
```sql
SELECT 
    artist_name,
    total_listening_hours,
    listening_time_rank,
    pct_of_total_listening,
    unique_tracks_played
FROM mart_artist_listening_time
ORDER BY total_listening_hours DESC
LIMIT 10;
```

### Artist Comparison
```sql
SELECT 
    artist_name,
    total_listening_hours,
    total_plays,
    total_listening_hours / NULLIF(total_plays, 0) * 60 as avg_track_minutes
FROM mart_artist_listening_time
WHERE total_plays > 10
ORDER BY total_listening_hours DESC;
```

---

## 3. How does listening behavior trend daily and weekly?

### Models to Use
- **Primary**: `mart_listening_trends`
- **Alternative**: `fct_track_plays` (for custom aggregations)

### Key Metrics Available
- `total_plays` - Daily play count
- `total_listening_minutes` - Daily listening time
- `unique_tracks` / `unique_artists` - Variety metrics
- `plays_7day_avg` - Rolling 7-day average
- `plays_morning` / `plays_afternoon` / `plays_evening` / `plays_night` - Time-of-day distribution
- `pct_weekend` - Weekend vs weekday split

### Daily Trends
```sql
SELECT 
    played_date,
    total_plays,
    total_listening_minutes / 60.0 as listening_hours,
    plays_7day_avg,
    unique_tracks,
    unique_artists
FROM mart_listening_trends
WHERE played_date >= DATEADD('day', -30, CURRENT_DATE())
ORDER BY played_date DESC;
```

### Weekly Patterns
```sql
SELECT 
    played_year,
    played_week,
    SUM(total_plays) as weekly_plays,
    SUM(total_listening_minutes) / 60.0 as weekly_hours,
    AVG(unique_tracks) as avg_daily_unique_tracks
FROM mart_listening_trends
GROUP BY played_year, played_week
ORDER BY played_year DESC, played_week DESC;
```

### Day-of-Week Analysis
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

### Hour-of-Day Analysis
```sql
SELECT 
    played_hour,
    COUNT(*) as total_plays,
    SUM(track_duration_minutes) / 60.0 as total_hours
FROM fct_track_plays
GROUP BY played_hour
ORDER BY played_hour;
```

---

## 4. How do audio features correlate with popularity?

### Models to Use
- **Primary**: `mart_track_popularity`
- **Supporting**: `dim_tracks`

### Key Audio Features
- `danceability` (0.0-1.0) - How suitable for dancing
- `energy` (0.0-1.0) - Intensity and activity level
- `valence` (0.0-1.0) - Musical positiveness
- `acousticness` (0.0-1.0) - Acoustic vs electronic
- `instrumentalness` (0.0-1.0) - Presence of vocals
- `tempo` (BPM) - Speed of the track

### Bucketed Features
- `danceability_bucket` - Categorized: Very Low to Very High
- `energy_bucket` - Categorized: Very Low to Very High
- `valence_bucket` - Categorized: Very Negative to Very Positive

### Feature Bucket Analysis
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

### Correlation Analysis
```sql
SELECT 
    CORR(danceability, play_count) as danceability_correlation,
    CORR(energy, play_count) as energy_correlation,
    CORR(valence, play_count) as valence_correlation,
    CORR(acousticness, play_count) as acousticness_correlation,
    CORR(instrumentalness, play_count) as instrumentalness_correlation,
    CORR(tempo, play_count) as tempo_correlation,
    CORR(track_popularity, play_count) as spotify_popularity_correlation
FROM mart_track_popularity
WHERE danceability IS NOT NULL;
```

### Feature Distribution
```sql
SELECT 
    ROUND(danceability, 1) as danceability_level,
    COUNT(*) as track_count,
    AVG(play_count) as avg_plays,
    SUM(play_count) as total_plays
FROM mart_track_popularity
WHERE danceability IS NOT NULL
GROUP BY danceability_level
ORDER BY danceability_level;
```

### Most Played by Profile
```sql
-- High Energy Dance Tracks
SELECT track_name, artist_name, play_count, danceability, energy
FROM mart_track_popularity
WHERE danceability > 0.7 AND energy > 0.7
ORDER BY play_count DESC
LIMIT 10;

-- Chill Acoustic Tracks
SELECT track_name, artist_name, play_count, acousticness, energy
FROM mart_track_popularity
WHERE acousticness > 0.7 AND energy < 0.5
ORDER BY play_count DESC
LIMIT 10;
```

---

## Model Selection Guide

### For Real-Time Analysis
Use `fct_track_plays` directly for:
- Custom time windows
- Specific date ranges
- Granular event-level analysis
- Custom aggregations not covered by marts

### For Standard Reporting
Use analytics marts for:
- Dashboard KPIs
- Standard business metrics
- Pre-aggregated insights
- Better query performance

### For Data Exploration
Use dimension tables for:
- Complete track/artist catalogs
- Metadata lookups
- Reference data
- Enrichment queries

---

## Data Grain Quick Reference

| Model | Grain | Use Case |
|-------|-------|----------|
| `fct_track_plays` | One row per play event | Event-level analysis, custom aggregations |
| `dim_tracks` | One row per track | Track catalog, metadata, audio features |
| `dim_artists` | One row per artist | Artist catalog, metadata |
| `mart_listening_trends` | One row per date | Daily/weekly trends, time-series |
| `mart_artist_listening_time` | One row per artist | Artist rankings, comparisons |
| `mart_track_popularity` | One row per track | Track rankings, feature analysis |

---

## Performance Tips

1. **Use marts for dashboards** - Pre-aggregated data loads faster
2. **Filter on date columns** - Use `played_date` for better partitioning
3. **Limit results** - Use TOP/LIMIT for large datasets
4. **Use appropriate grains** - Don't join to fact table if mart has what you need
5. **Index foreign keys** - Ensure track_id, artist_id are indexed

---

## Next Steps

For advanced analysis, consider:
- Creating additional marts for specific use cases
- Adding incremental materialization for large fact tables
- Implementing slowly changing dimensions (SCD) for tracks/artists
- Adding more granular time dimensions (hour, minute)
- Creating aggregate tables for common dashboard queries
