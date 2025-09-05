defmodule Tunez.Music.Artist do
  use Ash.Resource,
    otp_app: :tunez,
    domain: Tunez.Music,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshGraphql.Resource, AshJsonApi.Resource]

  graphql do
    type :artist
  end

  json_api do
    type "artist"
    # page 94
    includes [:albums]
    derive_filter? false
  end

  # ex: http://localhost:4000/api/json/artists?query=the&include=albums

  postgres do
    table "artists"
    repo Tunez.Repo
  end

  resource do
    description "A person or group of people that makes and releases music. 음악을 제작, 발표하는 개인이나 집단"
  end

  actions do
    defaults [:create, :read, :destroy]
    default_accept [:name, :biography]

    # PDF page 63
    read :search do
      description "===>> List Artists, optionally filtering by name. Now derive_filter? false"

      argument :query, :ci_string do
        constraints allow_empty?: true
        default ""
      end

      filter expr(contains(name, ^arg(:query)))

      pagination offset?: true, default_limit: 3
      # pagination keyset?: true, default_limit: 3 # PDF page 74

      # prepare build(load: [:album_count, :latest_album_year_released, :cover_image_url])
      # --> getting calcualtios are costly. so, comment out.
      # if interface Tunez.Music.search_artists is used, they are loaded by default. PDF 82
    end

    update :update do
      require_atomic? false
      accept [:name, :biography]

      change Tunez.Music.Changes.UpdatePreviousNames, where: [changing(:name)]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      # PDF page 69
      # to use sort_input.
      # example: Tunez.Music.search_artists("the", [query: [sort_input: "name"]])
      public? true
    end

    attribute :biography, :string

    create_timestamp :inserted_at, public?: true
    update_timestamp :updated_at, public?: true

    attribute :previous_names, {:array, :string} do
      default []
    end
  end

  relationships do
    has_many :albums, Tunez.Music.Album do
      # page 45
      sort year_released: :desc
      # page 93
      public? true
    end
  end

  # Aggregates perform some kind of calculation on records in a relationship,
  # Aggregates are not derived attributes, they are more like a summary of the relationship.
  # Aggregate simplifies calculations that are not derived attributes.
  aggregates do
    # same as calculate :album_count, :integer, expr(count(albums))
    count :album_count, :albums do
      # for sorting like iex(2)> Tunez.Music.search_artists("t", [query: [sort_input: "-album_count"]])
      public? true
    end

    # iex(1)> Tunez.Music.search_artists("t", [query: [sort: [album_count: :desc]]])

    # P84, P69
    first :latest_album_year_released, :albums, :year_released do
      public? true
    end

    first :cover_image_url, :albums, :cover_image_url
  end

  # iex(3)> Tunez.Music.search_artists("a", load: [:album_count, :album_count, :latest_album_year_released])
end

# #
# {
#   searchArtists(query: "a") {
#     results {
#       albumCount
#       latestAlbumYearReleased
#       id
#       name
#     }
#   }
# }

# {
#   getArtistById(id: "015ee671-e8cc-44f6-9225-57857b9e601f") {
#     name
#     albumCount
#     albums {
#       id
#       name
#     }
#   }
# }

# {
#   readArtists {
#     results {
#       id
#       name
#     }
#   }
# }

# mutation {
#   createArtist(
#     input: {biography: "A great Canadian band2", name: "Unleash the Rangers2"}
#   ) {
#     errors {
#       fields
#       message
#     }
#     result {
#       name
#       albumCount
#       id
#     }
#   }
# }

# mutation {
#   createAlbum(
#     input: {name: "New Album Name", artistId: "015ee671-e8cc-44f6-9225-57857b9e601f", yearReleased: 2022}
#   ) {
#     result {
#       id
#       name
#     }
#   }
# }
