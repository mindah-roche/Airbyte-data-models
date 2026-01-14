/*
    Analytics mart for artist listening time
    Answers: Which artists drive the most listening time?
    
    Provides aggregated listening metrics by artist
*/

with plays as (
    select * from {{ ref('fct_track_plays') }}
),

artists as (
    select * from {{ ref('dim_artists') }}
),

artist_stats as (
    select
        plays.artist_id,
        plays.artist_name,
        
        -- Play counts
        count(*) as total_plays,
        count(distinct plays.track_id) as unique_tracks_played,
        count(distinct plays.played_date) as active_days,
        
        -- Listening time
        sum(plays.track_duration_minutes) as total_listening_minutes,
        sum(plays.track_duration_minutes) / 60.0 as total_listening_hours,
        avg(plays.track_duration_minutes) as avg_track_duration_minutes,
        
        -- Temporal analysis
        min(plays.played_at) as first_played_at,
        max(plays.played_at) as last_played_at,
        datediff('day', min(plays.played_at), max(plays.played_at)) + 1 as days_span,
        
        -- Popularity metrics
        avg(plays.track_popularity) as avg_track_popularity,
        
        -- Audio feature preferences
        avg(plays.danceability) as avg_danceability,
        avg(plays.energy) as avg_energy,
        avg(plays.valence) as avg_valence,
        avg(plays.acousticness) as avg_acousticness,
        avg(plays.tempo) as avg_tempo
        
    from plays
    group by 
        plays.artist_id,
        plays.artist_name
),

ranked as (
    select
        artist_stats.*,
        
        -- Artist metadata
        artists.artist_popularity,
        artists.follower_count,
        artists.genres,
        
        -- Rankings
        row_number() over (order by total_listening_minutes desc) as listening_time_rank,
        row_number() over (order by total_plays desc) as play_count_rank,
        
        -- Percentages
        sum(total_listening_minutes) over () as total_listening_all_artists,
        total_listening_minutes / sum(total_listening_minutes) over () * 100 as pct_of_total_listening
        
    from artist_stats
    left join artists on artist_stats.artist_id = artists.artist_id
)

select * from ranked
order by total_listening_minutes desc
