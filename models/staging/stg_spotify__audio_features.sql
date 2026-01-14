/*
    Staging model for Spotify audio features
    Source: Airbyte raw table for Spotify audio features endpoint
    Grain: One row per track
*/

with source as (
    select * from {{ source('airbyte_raw', 'audio_features') }}
),

renamed as (
    select
        -- Primary key
        track_id,
        
        -- Audio feature metrics
        danceability,
        energy,
        key,
        loudness,
        mode,
        speechiness,
        acousticness,
        instrumentalness,
        liveness,
        valence,
        tempo,
        
        -- Timing
        duration_ms,
        time_signature,
        
        -- Metadata
        _airbyte_extracted_at as extracted_at
        
    from source
)

select * from renamed
