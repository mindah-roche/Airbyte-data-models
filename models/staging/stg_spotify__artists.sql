/*
    Staging model for Spotify artists
    Source: Airbyte raw table for Spotify artists endpoint
    Grain: One row per artist
*/

with source as (
    select * from {{ source('airbyte_raw', 'artists') }}
),

renamed as (
    select
        -- Primary key
        artist_id,
        
        -- Artist details
        artist_name,
        artist_popularity,
        follower_count,
        
        -- Genres (may be array or comma-separated)
        genres,
        
        -- URLs and identifiers
        artist_uri,
        external_url,
        
        -- Metadata
        _airbyte_extracted_at as extracted_at,
        _airbyte_extracted_at as updated_at
        
    from source
)

select * from renamed
