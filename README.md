# Airbyte-data-models
Designing Analytics-Ready Data Models on Top of Airbyte Raw Tables (Spotify Case Study)

## Overview

This dbt project transforms raw Spotify data synced by Airbyte into analytics-ready data models. The models are designed to answer key business questions about listening behavior, track popularity, and artist engagement.

## Business Questions Answered

1. **What tracks are listened to most over time?**
   - Use `fct_track_plays` for granular event-level data
   - Use `mart_track_popularity` for aggregated track metrics

2. **Which artists drive the most listening time?**
   - Use `mart_artist_listening_time` for artist rankings by listening time
   - Use `dim_artists` for artist-level statistics

3. **How does listening behavior trend daily and weekly?**
   - Use `mart_listening_trends` for time-series analysis
   - Includes daily, weekly, and hourly patterns

4. **How do audio features correlate with popularity?**
   - Use `mart_track_popularity` for tracks with audio features and play counts
   - Audio features include danceability, energy, valence, and more

## Data Model Structure

### Data Grain Definition

The project follows a dimensional modeling approach with clearly defined grains:

- **Fact Grain**: One row per track play event (`fct_track_plays`)
- **Track Grain**: One row per track (`dim_tracks`)
- **Artist Grain**: One row per artist (`dim_artists`)

### Model Layers

#### 1. Staging Layer (`models/staging/`)

Staging models clean and standardize raw Airbyte data:

- `stg_spotify__recently_played` - Recently played tracks (one row per play event)
- `stg_spotify__tracks` - Track details (one row per track)
- `stg_spotify__artists` - Artist details (one row per artist)
- `stg_spotify__audio_features` - Audio features (one row per track)

#### 2. Marts Layer (`models/marts/`)

**Fact Tables:**
- `fct_track_plays` - Core fact table with one row per play event
  - Contains: play timestamp, track/artist IDs, duration, context, audio features
  - Enables: time-series analysis, listening patterns

**Dimension Tables:**
- `dim_tracks` - One row per track with audio features and play statistics
- `dim_artists` - One row per artist with listening statistics

**Analytics Marts:**
- `mart_listening_trends` - Daily aggregated listening behavior
  - Total plays, unique tracks/artists, listening minutes
  - Time-of-day and day-of-week patterns
  - Rolling 7-day averages
  
- `mart_artist_listening_time` - Artist-level listening metrics
  - Total listening time and play counts
  - Artist rankings by listening time
  - Audio feature preferences per artist
  
- `mart_track_popularity` - Track-level popularity analysis
  - Play counts and rankings
  - Audio feature correlation data
  - Audio features bucketed for analysis

## Prerequisites

- dbt installed (dbt-core >= 1.0.0)
- Data warehouse connection (Snowflake, BigQuery, Redshift, etc.)
- Airbyte sync configured for Spotify data

## Setup

1. Configure your `profiles.yml` with connection details:
```yaml
spotify_analytics:
  target: dev
  outputs:
    dev:
      type: <your_warehouse>
      # add your connection details
```

2. Install dbt packages (if using dbt_utils):
```bash
dbt deps
```

3. Set up variables in `dbt_project.yml` or pass at runtime:
```yaml
vars:
  raw_database: your_raw_database
  raw_schema: airbyte_raw
```

## Usage

Run all models:
```bash
dbt run
```

Run specific model layer:
```bash
dbt run --select staging
dbt run --select marts
```

Run tests:
```bash
dbt test
```

Generate documentation:
```bash
dbt docs generate
dbt docs serve
```

## Example Queries

### Top 10 most played tracks
```sql
SELECT 
    track_name,
    artist_name,
    play_count,
    play_count_rank
FROM mart_track_popularity
ORDER BY play_count DESC
LIMIT 10;
```

### Artists with most listening time
```sql
SELECT 
    artist_name,
    total_listening_hours,
    listening_time_rank,
    pct_of_total_listening
FROM mart_artist_listening_time
ORDER BY total_listening_hours DESC
LIMIT 10;
```

### Daily listening trends
```sql
SELECT 
    played_date,
    total_plays,
    total_listening_minutes,
    plays_7day_avg,
    unique_tracks,
    unique_artists
FROM mart_listening_trends
ORDER BY played_date DESC
LIMIT 30;
```

### Audio features vs popularity correlation
```sql
SELECT 
    danceability_bucket,
    energy_bucket,
    AVG(play_count) as avg_plays,
    AVG(track_popularity) as avg_popularity,
    COUNT(*) as track_count
FROM mart_track_popularity
WHERE danceability IS NOT NULL
GROUP BY danceability_bucket, energy_bucket
ORDER BY avg_plays DESC;
```

## Project Structure

```
├── dbt_project.yml          # dbt project configuration
├── models/
│   ├── staging/             # Staging models (views)
│   │   ├── schema.yml       # Source and staging model definitions
│   │   ├── stg_spotify__recently_played.sql
│   │   ├── stg_spotify__tracks.sql
│   │   ├── stg_spotify__artists.sql
│   │   └── stg_spotify__audio_features.sql
│   └── marts/               # Analytics models (tables)
│       ├── schema.yml       # Mart model definitions
│       ├── fct_track_plays.sql
│       ├── dim_tracks.sql
│       ├── dim_artists.sql
│       ├── mart_listening_trends.sql
│       ├── mart_artist_listening_time.sql
│       └── mart_track_popularity.sql
└── README.md
```

## Notes

- The staging models assume Airbyte raw tables follow the default naming convention: `_airbyte_raw_{stream_name}`
- Audio feature values range from 0.0 to 1.0 (danceability, energy, valence, etc.)
- Track popularity is a Spotify score from 0-100
- Date/time functions may need adjustment based on your data warehouse SQL dialect
