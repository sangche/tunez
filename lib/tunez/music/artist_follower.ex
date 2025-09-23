defmodule Tunez.Music.ArtistFollower do
  use Ash.Resource,
    otp_app: :tunez,
    domain: Tunez.Music,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshGraphql.Resource]

  graphql do
    type :artist_follower
  end

  postgres do
    table "artist_followers"
    repo Tunez.Repo

    references do
      # delete all these join resource(ArtistFollower) records that belong to an artist if the artist is deleted
      # delete all these join resource(ArtistFollower) records that belong to a user if the user is deleted
      reference :artist, on_delete: :delete, index?: true
      reference :follower, on_delete: :delete

      # each record of this join resource represents a user following an artist(link from user to artist)
    end
  end

  actions do
    defaults [:read]

    create :create do
      # :artist_id is an attribute of the resource, via the :artist relationship. Page 214
      accept [:artist_id]

      change relate_actor(:follower, allow_nil?: false)
    end

    destroy :destroy do
      argument :artist_id, :uuid do
        allow_nil? false
      end

      change filter expr(
                      artist_id == ^arg(:artist_id) &&
                        follower_id == ^actor(:id)
                    )
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if always()
    end

    policy action_type(:create) do
      authorize_if actor_present()
    end

    policy action_type(:destroy) do
      authorize_if actor_present()
    end
  end

  relationships do
    belongs_to :artist, Tunez.Music.Artist do
      primary_key? true
      allow_nil? false
    end

    belongs_to :follower, Tunez.Accounts.User do
      primary_key? true
      allow_nil? false
    end
  end
end
