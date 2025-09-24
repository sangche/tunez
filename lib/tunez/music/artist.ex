defmodule Tunez.Music.Artist do
  use Ash.Resource,
    otp_app: :tunez,
    domain: Tunez.Music,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshGraphql.Resource, AshJsonApi.Resource],
    authorizers: [Ash.Policy.Authorizer]

  graphql do
    type :artist

    # only attributes below are exposed for filtering to client.
    filterable_fields [
      :name,
      :album_count,
      :cover_image_url,
      :inserted_at,
      :latest_album_year_released,
      :updated_at
    ]

    # if above not defined, everything will be exposed for filtering to client by default.
    # if you want to expose NO filter at all, use:
    # derive_filter? false

    # But used as below is not limited to above.
    # ex: Tunez.Music.search_artists("the", [query: [filter: %{album_count: %{gt: 2}}]])
  end

  json_api do
    type "artist"
    # page 94
    # page 204
    includes albums: [:tracks]
    derive_filter? false
  end

  # ex: http://localhost:4000/api/json/artists?query=the&include=albums
  # http://localhost:4000/api/json/artists/02a3cd19-24f7-4fde-8460-6eadb2618f02/albums?include=tracks

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

  # Tunez.Music.search_artists("the", load: [:album_count, :latest_album_year_released]) <-- by :search in policy
  # Tunez.Music.get_artist_by_id("e264e43f-026f-42b5-b163-5a61205449f4") <-- by :read in policy
  # Tunez.Music.create_artist(%{name: "New Artist"}) <-- Error Forbidden

  # admin = %Tunez.Accounts.User{role: :admin}
  # Tunez.Music.create_artist(%{name: "policy create testing New Artist"}, actor: admin) <-- pass
  policies do
    # policy action([:read, :search]) do
    #   authorize_if always()
    # end

    # same as above
    policy action_type(:read) do
      # simple check
      authorize_if always()
      # below is filter check
      # authorize_if expr(name == "Vanadine")
      # simple check: admin can see all artists
      # authorize_if actor_attribute_equals(:role, :admin)
    end

    # Tunez.Music.read_artists will show only Vanadine
    # admin = %Tunez.Accounts.User{role: :admin}
    # Tunez.Music.read_artists(actor: admin) # will show all artists

    policy action(:create) do
      authorize_if actor_attribute_equals(:role, :admin)
    end

    policy action(:update) do
      authorize_if actor_attribute_equals(:role, :admin)
      authorize_if actor_attribute_equals(:role, :editor)
    end

    policy action(:destroy) do
      authorize_if actor_attribute_equals(:role, :admin)
    end
  end

  changes do
    change relate_actor(:created_by, allow_nil?: true), on: [:create]
    # <--- for all create type
    change relate_actor(:updated_by, allow_nil?: true)
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

    # P 151 need to ash.codegen migrantion
    belongs_to :created_by, Tunez.Accounts.User
    belongs_to :updated_by, Tunez.Accounts.User

    has_many :follower_relationships, Tunez.Music.ArtistFollower

    many_to_many :followers, Tunez.Accounts.User do
      join_relationship :follower_relationships
      destination_attribute_on_join_resource :follower_id
    end
  end

  calculations do
    calculate :followed_by_me,
              :boolean,
              expr(exists(follower_relationships, follower_id == ^actor(:id)))
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

    # Page 221
    count :follower_count, :follower_relationships
  end
end

# How to query from GraphiQL: http://localhost:4000/gql/playground

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
#   searchArtists(query: "a", limit: 4) {
#     results {
#       albumCount
#       latestAlbumYearReleased
#       name
#     }
#   }
# }

# {
#   searchArtists(query: "o", limit: 4, filter: {name: {eq: "Violet Depths"}}) {
#     results {
#       albumCount
#       latestAlbumYearReleased
#       name
#     }
#   }
# }

# {
#   searchArtists(query: "a", limit: 4, filter: {albumCount: {eq: 2}}) {
#     results {
#       albumCount
#       latestAlbumYearReleased
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

# {
#   readArtists(filter: {latestAlbumYearReleased: { lessThan: 2010 } }) {
#     results {
#       name
#       latestAlbumYearReleased
#       albums {
#         name
#       }
#     }
#   }
# }

# {
#   readArtists(filter: { insertedAt: { greaterThan: "2025-09-01T01:27:26.133806Z" } }) {
#     results {
#       name
#       insertedAt
#       latestAlbumYearReleased
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
