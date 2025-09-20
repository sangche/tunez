defmodule Tunez.Music.Calculations.SecondsToMinutes do
  use Ash.Resource.Calculation

  # load, describe, expression, besides calculate. Page 196-197
  # calculations in Elixir code level, using calculate/3 is useful,
  # but it’s not the optimalway to do things.

  # @impl true
  # def calculate(tracks, _opts, _context) do
  #   # Code to calculate duration for each track in the list of tracks
  #   Enum.map(tracks, fn %{duration_seconds: duration} ->
  #     seconds =
  #       rem(duration, 60)
  #       |> Integer.to_string()
  #       |> String.pad_leading(2, "0")

  #     "#{div(duration, 60)}:#{seconds}"
  #   end)
  # end

  # It’s better to do calculations in the database layer, using expression.
  # see Page 198.
  @impl true
  def expression(_opts, _context) do
    expr(
      fragment("? / 60 || to_char(? * interval '1s', ':SS')", duration_seconds, duration_seconds)
    )
  end
end
