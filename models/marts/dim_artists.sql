/*
    Dimension table for artists
    Grain: One row per artist
    
    This provides a complete view of all artists with their attributes
*/

with artists as (
    select * from {{ ref('stg_spotify__artists') }}
),

-- Get play statistics from the fact table
play_stats as (
    select
        artist_id,
        count(*) as total_plays,
        count(distinct track_id) as unique_tracks_played,
        sum(track_duration_ms) / 1000.0 / 60.0 as total_listening_minutes,
        min(played_at) as first_played_at,
        max(played_at) as last_played_at
    from {{ ref('fct_track_plays') }}
    group by artist_id
),

final as (
    select
        -- Primary key
        artists.artist_id,
        
        -- Artist details
        artists.artist_name,
        artists.artist_popularity,
        artists.follower_count,
        artists.genres,
        
        -- Play statistics
        coalesce(play_stats.total_plays, 0) as total_plays,
        coalesce(play_stats.unique_tracks_played, 0) as unique_tracks_played,
        coalesce(play_stats.total_listening_minutes, 0) as total_listening_minutes,
        play_stats.first_played_at,
        play_stats.last_played_at,
        
        -- URLs
        artists.artist_uri,
        artists.external_url,
        
        -- Metadata
        artists.updated_at
        
    from artists
    left join play_stats on artists.artist_id = play_stats.artist_id
)

select * from final
