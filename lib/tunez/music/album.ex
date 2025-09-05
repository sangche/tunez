defmodule Tunez.Music.Album do
  use Ash.Resource,
    otp_app: :tunez,
    domain: Tunez.Music,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshGraphql.Resource, AshJsonApi.Resource]

  graphql do
    type :album
  end

  json_api do
    type "album"
    derive_filter? false
  end

  postgres do
    table "albums"
    repo Tunez.Repo

    references do
      reference :artist, index?: true, on_delete: :delete
    end
  end

  resource do
    description "많은 음악 곡들을 수록하고 있는 음반. 음악을 제작, 발표하는 개인이나 집단에 의해 제작됨"
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:name, :year_released, :cover_image_url, :artist_id]
    end

    update :update do
      accept [:name, :year_released, :cover_image_url]
    end
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

  relationships do
    belongs_to :artist, Tunez.Music.Artist do
      allow_nil? false
    end
  end

  def next_year, do: Date.utc_today().year + 1

  # PDF 75
  # iex(1)> Tunez.Music.get_artist_by_id("082b0b45-8c4a-459f-8d15-85ba026c9442", load: [albums: [:years_ago]])
  # iex(2)> Tunez.Music.get_artist_by_id("082b0b45-8c4a-459f-8d15-85ba026c9442", load: [albums: [:string_years_ago]])
  # iex(3)> Tunez.Music.get_artist_by_id("082b0b45-8c4a-459f-8d15-85ba026c9442", load: [albums: [:years_ago, :artist]])
  calculations do
    calculate :years_ago, :integer, expr(2025 - year_released)

    calculate :string_years_ago,
              :string,
              expr("wow, this was released " <> years_ago <> " years ago!")
  end

  # book page 48. need to ash.codegen migrantion
  identities do
    identity :unique_album_names_per_artist, [:name, :artist_id],
      message: "already exists for this artist"
  end
end
