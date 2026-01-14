# Data Model Lineage

## Overview
This document describes the data lineage and relationships between models in the Spotify Analytics dbt project.

## Data Flow

```
Raw Airbyte Tables
    ├── _airbyte_raw_recently_played
    ├── _airbyte_raw_tracks
    ├── _airbyte_raw_artists
    └── _airbyte_raw_audio_features
            ↓
Staging Models (views)
    ├── stg_spotify__recently_played
    ├── stg_spotify__tracks
    ├── stg_spotify__artists
    └── stg_spotify__audio_features
            ↓
Marts Models (tables)
    ├── fct_track_plays ←─────────────┐
    │   (combines all staging models)  │
    │                                   │
    ├── dim_tracks                     │
    │   (tracks + audio features + play stats from fct_track_plays)
    │                                   │
    ├── dim_artists                    │
    │   (artists + play stats from fct_track_plays)
    │                                   │
    ├── mart_listening_trends          │
    │   (aggregates fct_track_plays by date)
    │                                   │
    ├── mart_artist_listening_time     │
    │   (aggregates fct_track_plays by artist + joins dim_artists)
    │                                   │
    └── mart_track_popularity          │
        (aggregates fct_track_plays by track + joins dim_tracks)
```

## Model Dependencies

### Staging Layer
- `stg_spotify__recently_played` → depends on `source('airbyte_raw', 'recently_played')`
- `stg_spotify__tracks` → depends on `source('airbyte_raw', 'tracks')`
- `stg_spotify__artists` → depends on `source('airbyte_raw', 'artists')`
- `stg_spotify__audio_features` → depends on `source('airbyte_raw', 'audio_features')`

### Marts Layer - Fact Table
- `fct_track_plays` → depends on:
  - `stg_spotify__recently_played`
  - `stg_spotify__tracks` (optional enrichment)
  - `stg_spotify__artists` (optional enrichment)
  - `stg_spotify__audio_features` (optional enrichment)

### Marts Layer - Dimension Tables
- `dim_tracks` → depends on:
  - `stg_spotify__tracks`
  - `stg_spotify__audio_features`
  - `fct_track_plays` (for play statistics)

- `dim_artists` → depends on:
  - `stg_spotify__artists`
  - `fct_track_plays` (for play statistics)

### Marts Layer - Analytics Tables
- `mart_listening_trends` → depends on:
  - `fct_track_plays`

- `mart_artist_listening_time` → depends on:
  - `fct_track_plays`
  - `dim_artists`

- `mart_track_popularity` → depends on:
  - `fct_track_plays`
  - `dim_tracks`

## Build Order

The models should be built in this order (dbt handles this automatically based on dependencies):

1. **Stage 1**: Staging models (can run in parallel)
   - stg_spotify__recently_played
   - stg_spotify__tracks
   - stg_spotify__artists
   - stg_spotify__audio_features

2. **Stage 2**: Fact table
   - fct_track_plays

3. **Stage 3**: Dimension tables (can run in parallel)
   - dim_tracks
   - dim_artists

4. **Stage 4**: Analytics marts (can run in parallel)
   - mart_listening_trends
   - mart_artist_listening_time
   - mart_track_popularity

## Key Relationships

### Primary Keys
- `stg_spotify__recently_played.play_event_id` (surrogate key)
- `stg_spotify__tracks.track_id`
- `stg_spotify__artists.artist_id`
- `stg_spotify__audio_features.track_id`

### Foreign Keys in fct_track_plays
- `track_id` → `dim_tracks.track_id`
- `artist_id` → `dim_artists.artist_id`

## Data Refresh Strategy

### Full Refresh
All staging models should be refreshed to capture the latest data from Airbyte:
```bash
dbt run --select staging --full-refresh
```

### Incremental Updates
For large datasets, consider making `fct_track_plays` incremental:
- Track new play events based on `played_at` timestamp
- Update dimension tables with new aggregates

### Recommended Schedule
- **Staging models**: Run every time Airbyte syncs (hourly/daily)
- **Fact table**: Run after staging completes
- **Dimension tables**: Run after fact table completes
- **Analytics marts**: Run after dimensions complete or on-demand

## Testing Strategy

### Data Quality Tests
- **Uniqueness**: Primary keys in all tables
- **Not null**: Required fields (IDs, timestamps)
- **Referential integrity**: Foreign keys exist in dimension tables
- **Accepted values**: Enum fields (context_type, etc.)
- **Range checks**: Audio features (0.0-1.0), popularity (0-100)

### Business Logic Tests
- Total plays match between fact and aggregated marts
- No duplicate play events in fact table
- All tracks in fact table exist in dim_tracks
- All artists in fact table exist in dim_artists
