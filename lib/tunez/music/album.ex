defmodule Tunez.Music.Album do
  use Ash.Resource,
    otp_app: :tunez,
    domain: Tunez.Music,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshGraphql.Resource, AshJsonApi.Resource],
    authorizers: [Ash.Policy.Authorizer]

  graphql do
    type :album
  end

  # Page 204
  # http://localhost:4000/api/json/artists/015ee671-e8cc-44f6-9225-57857b9e601f/albums?include=tracks
  json_api do
    type "album"
    includes [:tracks]
    derive_filter? false
  end

  postgres do
    table "albums"
    repo Tunez.Repo

    references do
      reference :artist, index?: true, on_delete: :delete
      # delete all albums which belong to an artist if the artist is deleted
      # need to ash.codegen migrantion
    end
  end

  resource do
    description "많은 음악 곡들을 수록하고 있는 음반. 음악을 제작, 발표하는 개인이나 집단에 의해 제작됨"
  end

  actions do
    defaults [:read]

    destroy :destroy do
      primary? true

      # Before the album is destroyed, destroy all notifications that belong to this album
      # Return_notifications?: true for each notification to get :destroy action called,
      # so that the pub_sub publish :destroy can be triggered for each notification. P 245
      change cascade_destroy(:notifications,
               return_notifications?: true,
               after_action?: false
             )
    end

    create :create do
      accept [:name, :year_released, :cover_image_url, :artist_id]

      argument :tracks, {:array, :map}
      # change manage_relationship(:tracks, :tracks, type: :direct_control)
      # argument name == relationship name. P 185

      change manage_relationship(:tracks, type: :direct_control, order_is_key: :order)
    end

    update :update do
      accept [:name, :year_released, :cover_image_url]

      require_atomic? false
      argument :tracks, {:array, :map}

      change manage_relationship(:tracks, type: :direct_control, order_is_key: :order)
    end
  end

  policies do
    bypass actor_attribute_equals(:role, :admin) do
      authorize_if always()
    end

    policy action_type(:read) do
      authorize_if always()
    end

    policy action(:create) do
      authorize_if actor_attribute_equals(:role, :editor)
    end

    # this is to fix the problem mentioned above.
    # only editors can update or destroy albums they created.
    # so, if an editor creates an album, then later their role is changed to :user,
    # they can no longer update or destroy that album.
    policy action_type([:update, :destroy]) do
      authorize_if expr(^actor(:role) == :editor and created_by_id == ^actor(:id))
      # actor(who calls :update, :destroy): external variable binding with ^
    end
  end

  # assign current actor(who creates or updates this album) id to created_by_id, updated_by_id
  changes do
    change relate_actor(:created_by, allow_nil?: true), on: [:create]
    # <--- for only create type actions above, otherwise, update type actions below.
    change relate_actor(:updated_by, allow_nil?: true)

    change Tunez.Accounts.Changes.SendNewAlbumNotifications, on: [:create]
  end

  validations do
    validate numericality(:year_released,
               greater_than: 1950,
               less_than_or_equal_to: &__MODULE__.next_year/0
             ),
             where: [present(:year_released)],
             message: "must be between 1950 and next year"

    validate match(
               :cover_image_url,
               ~r"(^https://|/images/).+(\.png|\.jpg)$"
             ),
             where: [changing(:cover_image_url)],
             message: "반드시 must start with https:// or /images/"
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :year_released, :integer do
      allow_nil? false
    end

    attribute :cover_image_url, :string

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  def next_year, do: Date.utc_today().year + 1

  relationships do
    belongs_to :artist, Tunez.Music.Artist do
      allow_nil? false
    end

    # P 151 need to ash.codegen migrantion
    belongs_to :created_by, Tunez.Accounts.User
    belongs_to :updated_by, Tunez.Accounts.User

    # need public
    has_many :tracks, Tunez.Music.Track do
      sort order: :asc
      public? true
    end

    has_many :notifications, Tunez.Accounts.Notification
  end

  # iex(1)> Tunez.Music.get_album_by_id!("c9145c1c-74cf-4225-84c1-5897c76e2fb2", load: [:tracks])

  # PDF 75
  # iex(1)> Tunez.Music.get_artist_by_id("082b0b45-8c4a-459f-8d15-85ba026c9442", load: [albums: [:years_ago]])
  # iex(2)> Tunez.Music.get_artist_by_id("082b0b45-8c4a-459f-8d15-85ba026c9442", load: [albums: [:string_years_ago]])
  # iex(3)> Tunez.Music.get_artist_by_id("082b0b45-8c4a-459f-8d15-85ba026c9442", load: [albums: [:years_ago, :artist]])
  calculations do
    calculate :years_ago, :integer, expr(2025 - year_released)

    calculate :string_years_ago,
              :string,
              expr("wow, this was released " <> years_ago <> " years ago!")

    calculate :duration, :string, Tunez.Music.Calculations.SecondsToMinutes
  end

  aggregates do
    # sum of all track durations in this album, and store it in duration_seconds aggregate of Album
    sum :duration_seconds, :tracks, :duration_seconds
  end

  # book page 48. need to ash.codegen migrantion
  identities do
    identity :unique_album_names_per_artist, [:name, :artist_id],
      message: "already exists for this artist"
  end
end

# {
#   getAlbumById(id: "c9145c1c-74cf-4225-84c1-5897c76e2fb2") {
#     name
#     tracks {
#       name
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
