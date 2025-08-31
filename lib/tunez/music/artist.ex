defmodule Tunez.Music.Artist do
  use Ash.Resource, otp_app: :tunez, domain: Tunez.Music, data_layer: AshPostgres.DataLayer

  postgres do
    table "artists"
    repo Tunez.Repo
  end

  actions do
    defaults [:create, :read, :destroy]
    default_accept [:name, :biography]

    # PDF page 63
    read :search do
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
