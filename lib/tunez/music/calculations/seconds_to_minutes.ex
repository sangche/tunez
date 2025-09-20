defmodule Tunez.Music.Calculations.SecondsToMinutes do
  use Ash.Resource.Calculation

  # load, describe, expression, besides calculate. Page 196-197
  @impl true
  def load(query, opts, context) do
    IO.inspect(query, label: "SecondsToMinutes.load query")
    IO.inspect(opts, label: "SecondsToMinutes.load opts")
    IO.inspect(context, label: "SecondsToMinutes.load context")
    []
  end

  @impl true
  def calculate(tracks, _opts, _context) do
    # Code to calculate duration for each track in the list of tracks
    Enum.map(tracks, fn %{duration_seconds: duration} ->
      seconds =
        rem(duration, 60)
        |> Integer.to_string()
        |> String.pad_leading(2, "0")

      "#{div(duration, 60)}:#{seconds}"
    end)
  end
end
