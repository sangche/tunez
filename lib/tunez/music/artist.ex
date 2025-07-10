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

      # AshPhoenix.LiveView.page_from_params(params, 2)
      pagination offset?: true, default_limit: 3
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
end
