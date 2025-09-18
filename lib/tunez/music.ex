defmodule Tunez.Music do
  use Ash.Domain, otp_app: :tunez, extensions: [AshGraphql.Domain, AshJsonApi.Domain, AshPhoenix]

  graphql do
    queries do
      get Tunez.Music.Artist, :get_artist_by_id, :read
      list Tunez.Music.Artist, :read_artists, :read
      list Tunez.Music.Artist, :search_artists, :search
    end

    mutations do
      create Tunez.Music.Artist, :create_artist, :create
      update Tunez.Music.Artist, :update_artist, :update
      destroy Tunez.Music.Artist, :destroy_artist, :destroy

      create Tunez.Music.Album, :create_album, :create
      update Tunez.Music.Album, :update_album, :update
      destroy Tunez.Music.Album, :destroy_album, :destroy
    end

    # subscriptions do
    #   subscribe Tunez.Music.Artist, :resource_created do
    #     action_types :create
    #   end
    # end
  end

  json_api do
    routes do
      base_route "/artists", Tunez.Music.Artist do
        get :read
        index :search
        post :create
        patch :update
        delete :destroy
        # linking a list of albums to an artist. Page94
        related :albums, :read, primary?: true
      end

      # ex: http://localhost:4000/api/json/artists/082b0b45-8c4a-459f-8d15-85ba026c9442/albums

      base_route "/albums", Tunez.Music.Album do
        # get :read   # http://localhost:4000/api/json/albums/:album_id
        # index :read # http://localhost:4000/api/json/albums
        post :create
        patch :update
        delete :destroy
      end
    end
  end

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

      define :search_artists,
        action: :search,
        args: [:query],
        default_options: [
          load: [:album_count, :latest_album_year_released, :cover_image_url]
        ]
    end

    resource Tunez.Music.Album do
      define :create_album, action: :create
      define :get_album_by_id, action: :read, get_by: :id
      define :update_album, action: :update
      define :destroy_album, action: :destroy
    end

    resource Tunez.Music.Track
  end
end

# test
# iex(0)> Tunez.Music.search_artists("vio")
# iex(0)> Tunez.Music.search_artists2(%{query: "co"}) <-- PDF page 64

# iex(1)> require Ash.Query
# Ash.Query

# General way of query:
#
# iex(2)> Ash.Query.filter(Tunez.Music.Album, year_released == 2024)
# #Ash.Query<resource: Tunez.Music.Album,
#  filter: #Ash.Filter<year_released == 2024>>
# iex(3)> |> Ash.read()
# [debug] QUERY OK source="albums" db=49.0ms decode=5.7ms queue=69.3ms idle=186.6ms
# SELECT a0."id", a0."name", a0."artist_id", a0."inserted_at", a0."updated_at", a0."year_released", a0."cover_image_url" FROM "albums" AS a0 WHERE (a0."year_released"::bigint = $1::bigint) [2024]
# ↳ anonymous fn/3 in AshPostgres.DataLayer.run_query/2, at: lib/data_layer.ex:788
# {:ok,
#  [
#    %Tunez.Music.Album{
#      id: "141c0e42-c630-4d71-92d4-cfe8d91a5ce4",
#      name: "Eternal Tides",
#      year_released: 2024,
#      cover_image_url: "/images/albums/crystal_cove_eternal_tides.png",
#      inserted_at: ~U[2025-06-28 07:07:41.212758Z],
#      updated_at: ~U[2025-06-28 07:07:41.212758Z],
#      artist_id: "6013c9c7-9218-40cd-9f1d-8e23817c2f82",
#      artist: #Ash.NotLoaded<:relationship, field: :artist>,
#      __meta__: #Ecto.Schema.Metadata<:loaded, "albums">
#    }
#  ]}

# To use :search action defined in Artist resouce:

# iex(4)> Tunez.Music.Artist
# Tunez.Music.Artist
# iex(5)> |> Ash.Query.for_read(:search, %{query: "co"})
# #Ash.Query<
#   resource: Tunez.Music.Artist,
#   action: :search,
#   arguments: %{query: #Ash.CiString<"co">},
#   filter: #Ash.Filter<contains(name, #Ash.CiString<"co">)>
# >
# iex(6)> |> Ash.read()
# [debug] QUERY OK source="artists" db=53.2ms queue=20.1ms idle=772.6ms
# SELECT a0."id", a0."name", a0."biography", a0."inserted_at", a0."updated_at", a0."previous_names" FROM "artists" AS a0 WHERE (a0."name"::text ILIKE $1) ["%co%"]
# ↳ anonymous fn/3 in AshPostgres.DataLayer.run_query/2, at: lib/data_layer.ex:788
# {:ok,
#  [
#    %Tunez.Music.Artist{
#      id: "6013c9c7-9218-40cd-9f1d-8e23817c2f82",
#      name: "Crystal Cove",
#      biography: "Born from the salty air of the Bahamas, Crystal Cove was founded in 2011 by a group of musicians who shared a passion for the high seas and pirate lore. Their music, infused with rollicking rhythms and haunting melodies, tells tales of forgotten treasures, fierce battles, and mystical encounters on the ocean's vast expanse. As they toured across coastal cities, their theatrical performances, complete with pirate attire and stage props, captivated audiences and solidified their reputation as the premiere pirate metal band.",
#      inserted_at: ~U[2025-06-28 07:07:40.832040Z],
#      updated_at: ~U[2025-06-28 07:07:40.832040Z],
#      previous_names: [],
#      albums: #Ash.NotLoaded<:relationship, field: :albums>,
#      __meta__: #Ecto.Schema.Metadata<:loaded, "artists">
#    }
#  ]}

# see PDF 61
