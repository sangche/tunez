defmodule Tunez.Accounts.Changes.SendNewAlbumNotifications do
  use Ash.Resource.Change
  @impl true
  def change(changeset, _opts, _context) do
    IO.inspect(changeset, label: "changeset at change function call")

    cs =
      Ash.Changeset.after_action(changeset, fn changesetb, album ->
        IO.inspect(album, label: "new album")
        IO.inspect(changesetb, label: "changesetb")
        album = Ash.load!(album, artist: [:follower_relationships])
        IO.inspect(album, label: "new album relationships loaded")

        # album.artist.follower_relationships
        # |> Enum.map(fn %{follower_id: follower_id} ->
        #   %{album_id: album.id, user_id: follower_id}
        # end)
        # |> Ash.bulk_create!(Tunez.Accounts.Notification, :create)

        {:ok, album}
      end)

    IO.inspect(cs, label: "changeset after Changeset.after_action function call")

    cs
  end
end
