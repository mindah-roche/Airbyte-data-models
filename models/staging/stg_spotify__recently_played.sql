/*
    Staging model for Spotify recently played tracks
    Source: Airbyte raw table for Spotify recently played endpoint
    Grain: One row per play event
*/

with source as (
    select * from {{ source('airbyte_raw', 'recently_played') }}
),

renamed as (
    select
        -- Primary key
        {{ dbt_utils.generate_surrogate_key(['played_at', 'track_id']) }} as play_event_id,
        
        -- Timestamps
        cast(played_at as timestamp) as played_at,
        cast(played_at as date) as played_date,
        
        -- Track information
        track_id,
        track_name,
        track_duration_ms,
        track_popularity,
        
        -- Artist information
        artist_id,
        artist_name,
        
        -- Album information
        album_id,
        album_name,
        album_release_date,
        
        -- Context
        context_type,
        context_uri,
        
        -- Metadata
        _airbyte_extracted_at as extracted_at
        
    from source
)

select * from renamed
