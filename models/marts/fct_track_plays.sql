/*
    Fact table for track plays
    Grain: One row per track play event
    
    This table answers: What tracks are listened to most over time?
*/

with plays as (
    select * from {{ ref('stg_spotify__recently_played') }}
),

tracks as (
    select * from {{ ref('stg_spotify__tracks') }}
),

artists as (
    select * from {{ ref('stg_spotify__artists') }}
),

audio_features as (
    select * from {{ ref('stg_spotify__audio_features') }}
),

final as (
    select
        -- Primary key
        plays.play_event_id,
        
        -- Timestamps (for time-based analysis)
        plays.played_at,
        plays.played_date,
        extract(hour from plays.played_at) as played_hour,
        extract(dayofweek from plays.played_at) as played_day_of_week,
        extract(week from plays.played_at) as played_week,
        extract(month from plays.played_at) as played_month,
        extract(year from plays.played_at) as played_year,
        
        -- Foreign keys
        plays.track_id,
        plays.artist_id,
        plays.album_id,
        
        -- Play metrics
        plays.track_duration_ms,
        plays.track_duration_ms / 1000.0 / 60.0 as track_duration_minutes,
        
        -- Track attributes (denormalized for easy querying)
        plays.track_name,
        plays.track_popularity,
        
        -- Artist attributes
        plays.artist_name,
        
        -- Album attributes
        plays.album_name,
        plays.album_release_date,
        
        -- Context
        plays.context_type,
        plays.context_uri,
        
        -- Audio features (for correlation analysis)
        audio_features.danceability,
        audio_features.energy,
        audio_features.valence,
        audio_features.acousticness,
        audio_features.instrumentalness,
        audio_features.tempo,
        
        -- Metadata
        plays.extracted_at
        
    from plays
    left join tracks on plays.track_id = tracks.track_id
    left join artists on plays.artist_id = artists.artist_id
    left join audio_features on plays.track_id = audio_features.track_id
)

select * from final
