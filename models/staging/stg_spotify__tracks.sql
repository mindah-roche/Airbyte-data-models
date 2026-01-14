/*
    Staging model for Spotify tracks
    Source: Airbyte raw table for Spotify tracks endpoint
    Grain: One row per track
*/

with source as (
    select * from {{ source('airbyte_raw', 'tracks') }}
),

renamed as (
    select
        -- Primary key
        track_id,
        
        -- Track details
        track_name,
        track_duration_ms,
        track_popularity,
        explicit,
        
        -- Album information
        album_id,
        album_name,
        album_type,
        album_release_date,
        cast(album_release_date as date) as album_release_date_parsed,
        
        -- Artist information (primary artist)
        artist_id,
        artist_name,
        
        -- URLs and identifiers
        track_uri,
        external_url,
        isrc,
        
        -- Metadata
        _airbyte_extracted_at as extracted_at,
        _airbyte_extracted_at as updated_at
        
    from source
)

select * from renamed
