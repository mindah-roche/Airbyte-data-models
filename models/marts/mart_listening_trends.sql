/*
    Analytics mart for listening trends
    Answers: How does listening behavior trend daily and weekly?
    
    Provides aggregated listening metrics by date
*/

with plays as (
    select * from {{ ref('fct_track_plays') }}
),

daily_stats as (
    select
        played_date,
        played_year,
        played_month,
        played_week,
        
        -- Play counts
        count(*) as total_plays,
        count(distinct track_id) as unique_tracks,
        count(distinct artist_id) as unique_artists,
        
        -- Listening time
        sum(track_duration_minutes) as total_listening_minutes,
        avg(track_duration_minutes) as avg_track_duration_minutes,
        
        -- Hourly distribution
        count(case when played_hour between 0 and 5 then 1 end) as plays_night,
        count(case when played_hour between 6 and 11 then 1 end) as plays_morning,
        count(case when played_hour between 12 and 17 then 1 end) as plays_afternoon,
        count(case when played_hour between 18 and 23 then 1 end) as plays_evening,
        
        -- Day of week (1=Sunday, 7=Saturday in most SQL dialects)
        avg(case when played_day_of_week in (1, 7) then 1 else 0 end) as pct_weekend,
        
        -- Context analysis
        count(case when context_type = 'playlist' then 1 end) as plays_from_playlist,
        count(case when context_type = 'album' then 1 end) as plays_from_album,
        count(case when context_type = 'artist' then 1 end) as plays_from_artist,
        
        -- Audio feature averages
        avg(danceability) as avg_danceability,
        avg(energy) as avg_energy,
        avg(valence) as avg_valence,
        avg(tempo) as avg_tempo
        
    from plays
    group by 
        played_date,
        played_year,
        played_month,
        played_week
),

-- Add rolling averages
with_rolling as (
    select
        *,
        avg(total_plays) over (
            order by played_date 
            rows between 6 preceding and current row
        ) as plays_7day_avg,
        avg(total_listening_minutes) over (
            order by played_date 
            rows between 6 preceding and current row
        ) as listening_minutes_7day_avg
    from daily_stats
)

select * from with_rolling
order by played_date desc
