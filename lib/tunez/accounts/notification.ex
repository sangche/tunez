defmodule Tunez.Accounts.Notification do
  use Ash.Resource,
    otp_app: :tunez,
    domain: Tunez.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    notifiers: [Ash.Notifier.PubSub]

  postgres do
    table "notifications"
    repo Tunez.Repo

    references do
      reference :user, index?: true, on_delete: :delete
      reference :album, on_delete: :delete
    end
  end

  actions do
    defaults [:destroy]

    create :create do
      accept [:user_id, :album_id]
    end

    read :for_user do
      prepare build(load: [album: [:artist]], sort: [inserted_at: :desc])
      filter expr(user_id == ^actor(:id))
      # users will only ever get back for their own notifications
    end
  end

  policies do
    policy action(:create) do
      # At album creation, only inside this app can create notifications, using authorize?: false
      forbid_if always()
    end

    policy action(:for_user) do
      authorize_if actor_present()
    end

    policy action(:destroy) do
      # if actor of destroy is the same as the user of the destroyed notification
      authorize_if relates_to_actor_via(:user)
    end
  end

  # broadcast notifications with a topic 'notifications:<user_id>` whenever a notification is created for a user
  pub_sub do
    prefix "notifications"
    module TunezWeb.Endpoint
    # P. 241
    transform fn notification ->
      Map.take(notification.data, [:id, :user_id, :album_id])
    end

    publish :create, [:user_id]
  end

  attributes do
    uuid_primary_key :id
    create_timestamp :inserted_at
  end

  relationships do
    belongs_to :user, Tunez.Accounts.User do
      allow_nil? false
    end

    belongs_to :album, Tunez.Music.Album do
      allow_nil? false
    end
  end
end
