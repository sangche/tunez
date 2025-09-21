defmodule Tunez.Music.Track do
  use Ash.Resource,
    otp_app: :tunez,
    domain: Tunez.Music,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshGraphql.Resource, AshJsonApi.Resource]

  graphql do
    type :track
  end

  json_api do
    type "track"
    # P204
    default_fields [:name]
  end

  postgres do
    table "tracks"
    repo Tunez.Repo

    references do
      reference :album, index?: true, on_delete: :delete
    end
  end

  # primary? true means:
  # primary action of action type 'create' to insert new data is ':create'
  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:order, :name, :album_id]
      argument :duration, :string, allow_nil?: false
      change Tunez.Music.Changes.MinutesToSeconds, only_when_valid?: true
    end

    update :update do
      primary? true
      accept [:order, :name]
      require_atomic? false
      argument :duration, :string, allow_nil?: false
      change Tunez.Music.Changes.MinutesToSeconds, only_when_valid?: true
    end
  end

  preparations do
    prepare build(load: [:number, :duration])
  end

  attributes do
    uuid_primary_key :id

    attribute :order, :integer do
      allow_nil? false
    end

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :duration_seconds, :integer do
      allow_nil? false
      constraints min: 1
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :album, Tunez.Music.Album do
      allow_nil? false
    end
  end

  calculations do
    # done in the DB layer, not in Elixir. Page 197
    calculate :number, :integer, expr(order + 1)

    calculate :duration, :string, Tunez.Music.Calculations.SecondsToMinutes
  end

  # a track belongs to an album, an album has many tracks
  # no policies, all actions are via tracks form inside the album context for now
  # so policies are inherited from album. see Page 188
  # If we create Track form directly, we need policies here, to be safe.
end
