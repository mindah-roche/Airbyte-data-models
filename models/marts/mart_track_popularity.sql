/*
    Analytics mart for track popularity
    Answers: How do audio features correlate with popularity?
    
    Provides track-level metrics with audio features for correlation analysis
*/

with plays as (
    select * from {{ ref('fct_track_plays') }}
),

tracks as (
    select * from {{ ref('dim_tracks') }}
),

track_stats as (
    select
        plays.track_id,
        plays.track_name,
        plays.artist_id,
        plays.artist_name,
        plays.album_name,
        
        -- Play metrics
        count(*) as play_count,
        count(distinct plays.played_date) as active_days,
        
        -- Listening time
        sum(plays.track_duration_minutes) as total_listening_minutes,
        
        -- Temporal
        min(plays.played_at) as first_played_at,
        max(plays.played_at) as last_played_at,
        
        -- Get one set of audio features (they should be consistent per track)
        max(plays.track_popularity) as track_popularity,
        max(plays.danceability) as danceability,
        max(plays.energy) as energy,
        max(plays.valence) as valence,
        max(plays.acousticness) as acousticness,
        max(plays.instrumentalness) as instrumentalness,
        max(plays.tempo) as tempo
        
    from plays
    group by 
        plays.track_id,
        plays.track_name,
        plays.artist_id,
        plays.artist_name,
        plays.album_name
),

ranked as (
    select
        track_stats.*,
        
        -- Track metadata
        tracks.track_duration_minutes,
        tracks.album_release_date,
        tracks.explicit,
        
        -- Rankings
        row_number() over (order by play_count desc) as play_count_rank,
        row_number() over (order by total_listening_minutes desc) as listening_time_rank,
        
        -- Percentages
        play_count / sum(play_count) over () * 100 as pct_of_total_plays,
        
        -- Audio feature buckets for correlation analysis
        case 
            when danceability >= 0.8 then 'Very High'
            when danceability >= 0.6 then 'High'
            when danceability >= 0.4 then 'Medium'
            when danceability >= 0.2 then 'Low'
            else 'Very Low'
        end as danceability_bucket,
        
        case 
            when energy >= 0.8 then 'Very High'
            when energy >= 0.6 then 'High'
            when energy >= 0.4 then 'Medium'
            when energy >= 0.2 then 'Low'
            else 'Very Low'
        end as energy_bucket,
        
        case 
            when valence >= 0.8 then 'Very Positive'
            when valence >= 0.6 then 'Positive'
            when valence >= 0.4 then 'Neutral'
            when valence >= 0.2 then 'Negative'
            else 'Very Negative'
        end as valence_bucket
        
    from track_stats
    left join tracks on track_stats.track_id = tracks.track_id
)

select * from ranked
order by play_count desc
