defmodule Tunez.Music do
  use Ash.Domain, otp_app: :tunez, extensions: [AshPhoenix]

  # we can customize only the form_to_create_album action by using the forms3 DSL,
  # from the AshPhoenix domain extension. see page 41
  forms do
    form :create_album, args: [:artist_id]
  end

  # AshPhoenix extension will autogen form_to_create_artist, form_to_...

  resources do
    resource Tunez.Music.Artist do
      define :create_artist, action: :create
      define :read_artists, action: :read
      define :get_artist_by_id, action: :read, get_by: :id
      define :update_artist, action: :update
      define :destroy_artist, action: :destroy
    end

    resource Tunez.Music.Album do
      define :create_album, action: :create
      define :get_album_by_id, action: :read, get_by: :id
      define :update_album, action: :update
      define :destroy_album, action: :destroy
    end
  end
end
