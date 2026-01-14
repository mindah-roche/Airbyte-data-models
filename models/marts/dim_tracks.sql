/*
    Dimension table for tracks
    Grain: One row per track
    
    This provides a complete view of all tracks with their attributes
*/

with tracks as (
    select * from {{ ref('stg_spotify__tracks') }}
),

audio_features as (
    select * from {{ ref('stg_spotify__audio_features') }}
),

-- Get play statistics from the fact table
play_stats as (
    select
        track_id,
        count(*) as total_plays,
        min(played_at) as first_played_at,
        max(played_at) as last_played_at
    from {{ ref('fct_track_plays') }}
    group by track_id
),

final as (
    select
        -- Primary key
        tracks.track_id,
        
        -- Track details
        tracks.track_name,
        tracks.track_duration_ms,
        tracks.track_duration_ms / 1000.0 / 60.0 as track_duration_minutes,
        tracks.track_popularity,
        tracks.explicit,
        
        -- Album information
        tracks.album_id,
        tracks.album_name,
        tracks.album_type,
        tracks.album_release_date,
        tracks.album_release_date_parsed,
        
        -- Artist information
        tracks.artist_id,
        tracks.artist_name,
        
        -- Audio features
        audio_features.danceability,
        audio_features.energy,
        audio_features.key,
        audio_features.loudness,
        audio_features.mode,
        audio_features.speechiness,
        audio_features.acousticness,
        audio_features.instrumentalness,
        audio_features.liveness,
        audio_features.valence,
        audio_features.tempo,
        audio_features.time_signature,
        
        -- Play statistics
        coalesce(play_stats.total_plays, 0) as total_plays,
        play_stats.first_played_at,
        play_stats.last_played_at,
        
        -- URLs
        tracks.track_uri,
        tracks.external_url,
        tracks.isrc,
        
        -- Metadata
        tracks.updated_at
        
    from tracks
    left join audio_features on tracks.track_id = audio_features.track_id
    left join play_stats on tracks.track_id = play_stats.track_id
)

select * from final
