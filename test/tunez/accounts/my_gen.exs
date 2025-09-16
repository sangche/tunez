defmodule My.Generator do
  use Ash.Generator

  def user(opts \\ []) do
    changeset_generator(
      Tunez.Accounts.User,
      :register_with_password,
      defaults: [
        # Generates unique values using an auto-incrementing sequence
        # eg. `user1@example.com`, `user2@example.com`, etc.
        email: sequence(:user_email, &"user#{&1}@example.com"),
        password: "password",
        password_confirmation: "password"
      ],
      overrides: opts,
      after_action: fn user ->
        role = opts[:role] || :user
        email = opts[:email] || user.email
        user = Tunez.Accounts.set_user_role!(user, role, authorize?: false)
        Tunez.Accounts.set_user_email!(user, email, authorize?: false)
      end
    )
  end
end

# Demonstration test - this is only to show how to call generators!
defmodule Tunez.Accounts.UserTest do
  # use ExUnit.Case
  use Tunez.DataCase, async: true

  @tag :hey
  test "can create user records" do
    # stream data
    us = My.Generator.user()
    IO.inspect(us, label: "user")
    # Generate a user with all default data
    user = My.Generator.generate(us)
    IO.inspect(user, label: "Generated user")

    IO.inspect(My.Generator.generate(My.Generator.user(email: "hello@test.com", role: :editor)),
      label: "Generated user given email"
    )

    # Or generate more than one user, with some specific data
    two_admins = My.Generator.generate_many(My.Generator.user(role: :admin), 2)
    IO.inspect(two_admins, label: "Generated two admins")
  end

  @tag :skip
  test "can create user records - skipped" do
    IO.inspect("This test is skipped", label: "Skipped")
  end
end

# $ mix test test/tunez/accounts/my_gen.exs
# $ mix test test/tunez/accounts/my_gen.exs --trace

# *user: #StreamData<79.32808772/2 in StreamData.map/2>
# Generated user: %Tunez.Accounts.User{
#   id: "3f96d52f-74d0-4c9e-bbee-378264bd4012",
#   email: #Ash.CiString<"user0@example.com">,
#   confirmed_at: nil,
#   role: :user,
#   __meta__: #Ecto.Schema.Metadata<:loaded, "users">
# }
# Generated user given email: %Tunez.Accounts.User{
#   id: "7e05f2f7-b9ce-42b6-b7b5-6a9beb8a645d",
#   email: #Ash.CiString<"hello@test.com">,
#   confirmed_at: nil,
#   role: :editor,
#   __meta__: #Ecto.Schema.Metadata<:loaded, "users">
# }
# Generated two admins: [
#   %Tunez.Accounts.User{
#     id: "b5fa5182-728a-4886-ad65-dc840bf56ccb",
#     email: #Ash.CiString<"user1@example.com">,
#     confirmed_at: nil,
#     role: :admin,
#     __meta__: #Ecto.Schema.Metadata<:loaded, "users">
#   },
#   %Tunez.Accounts.User{
#     id: "d5eecd4b-8294-4ce7-84b6-96e2723bea6b",
#     email: #Ash.CiString<"user2@example.com">,
#     confirmed_at: nil,
#     role: :admin,
#     __meta__: #Ecto.Schema.Metadata<:loaded, "users">
#   }
# ]
# .
# Finished in 0.3 seconds (0.3s async, 0.00s sync)
# 2 tests, 0 failures, 1 skipped

# $ mix test test/tunez/accounts/my_gen.exs:32
# $ mix test test/tunez/accounts/my_gen.exs --only hey

defmodule MyTestGenerator do
  use Ash.Generator

  def user(opts \\ []) do
    changeset_generator(
      Tunez.Accounts.User,
      :register_with_password,
      defaults: [
        email: sequence(:user_email, &"user#{&1}@example.com"),
        password: "password",
        password_confirmation: "password"
      ],
      overrides: opts,
      after_action: fn user ->
        role = opts[:role] || :user
        email = opts[:email] || user.email
        user = Tunez.Accounts.set_user_role!(user, role, authorize?: false)
        Tunez.Accounts.set_user_email!(user, email, authorize?: false)
      end
    )
  end

  def artist(opts \\ []) do
    after_action =
      if opts[:album_count] do
        fn artist ->
          generate_many(album(artist_id: artist.id), opts[:album_count])
          Ash.load!(artist, :albums)
        end
      end

    actor =
      opts[:actor] ||
        once(:default_actor, fn ->
          generate(user(role: :admin))
        end)

    changeset_generator(
      Tunez.Music.Artist,
      :create,
      defaults: [name: sequence(:artist_name, &"Artist #{&1}")],
      actor: actor,
      overrides: opts,
      after_action: after_action
    )
  end

  def album(opts \\ []) do
    actor =
      opts[:actor] ||
        once(:default_actor, fn ->
          generate(user(role: opts[:actor_role] || :editor))
        end)

    artist_id =
      opts[:artist_id] ||
        once(:default_artist_id, fn ->
          generate(artist()).id
        end)

    changeset_generator(
      Tunez.Music.Album,
      :create,
      defaults: [
        name: sequence(:album_name, &"Album #{&1}"),
        year_released: StreamData.integer(1951..2024),
        artist_id: artist_id,
        cover_image_url: nil
      ],
      overrides: opts,
      actor: actor
    )
  end

  def seeded_artist(opts \\ []) do
    actor =
      opts[:actor] ||
        once(:default_actor, fn ->
          generate(user(role: :admin))
        end)

    seed_generator(
      %Tunez.Music.Artist{name: sequence(:artist_name, &"Artist #{&1}")},
      actor: actor,
      overrides: opts
    )
  end
end

# P. 167
# 'seeded_artist' is a drop-in replacement for the 'artist' generator, so you can still call
# functions like generate_many(seeded_artist(), 3). You could even put both seed and
# changeset generators in the same function and switch between them based
# on an input option. It’s a flexible pattern that allows you to generate exactly
# the data you need, in an explicit yet succinct way, and with the most confi-
# dence that what you’re generating is real.

#####

defmodule Tunez.TestAll do
  use Tunez.DataCase, async: true
  alias Tunez.Music

  describe "Tunez.Music.search_artists/1-2" do
    defp names(page), do: Enum.map(page.results, & &1.name)

    test "can filter by partial name matches" do
      ["hello", "goodbye", "what?"]
      |> Enum.each(&MyTestGenerator.generate(MyTestGenerator.artist(name: &1)))

      assert Enum.sort(names(Music.search_artists!("o"))) == ["goodbye", "hello"]
      assert names(Music.search_artists!("oo")) == ["goodbye"]
      assert names(Music.search_artists!("he")) == ["hello"]
    end

    test "can sort by number of album releases" do
      MyTestGenerator.generate(MyTestGenerator.artist(name: "two", album_count: 2))
      MyTestGenerator.generate(MyTestGenerator.artist(name: "none"))
      MyTestGenerator.generate(MyTestGenerator.artist(name: "one", album_count: 1))
      MyTestGenerator.generate(MyTestGenerator.artist(name: "three", album_count: 3))

      actual =
        names(Music.search_artists!("", query: [sort_input: "-album_count"]))

      # "none" is not included in actual, because 3 items per page
      # to change per page. see lib/tunez/music/artist.ex line 63 default_limit: 4
      assert actual == ["three", "two", "one", "none"]
    end
  end

  test "year_released must be between 1950 and next year" do
    admin = MyTestGenerator.generate(MyTestGenerator.user(role: :admin))
    artist = MyTestGenerator.generate(MyTestGenerator.artist())
    # The assertion isn't really needed here, but we want to signal to
    # our future selves that this is part of the test, not the setup.
    assert %{artist_id: artist.id, name: "test 2024", year_released: 2024}
           |> Music.create_album!(actor: admin)

    # Using `assert_raise`
    assert_raise Ash.Error.Invalid, ~r/must be between 1950 and next year/, fn ->
      %{artist_id: artist.id, name: "test 1925", year_released: 1925}
      |> Music.create_album!(actor: admin)
    end

    # Using `assert_has_error` - note the lack of bang to return the error
    %{artist_id: artist.id, name: "test 1950", year_released: 1950}
    |> Music.create_album(actor: admin)
    |> Ash.Test.assert_has_error(Ash.Error.Invalid, fn error ->
      match?(%{message: "must be between 1950 and next year"}, error)
    end)
  end
end
