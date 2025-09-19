defmodule Tunez.Music.Calculations.SecondsToMinutes do
  # use Ash.Resource.Calculation

  def init(_opts) do
    {:ok, 0}
  end

  def load(tracks, _opts, _context) do
    IO.inspect(tracks, label: "tracks in SecondsToMinutes")

    Enum.map(tracks, fn %{duration_seconds: duration} ->
      seconds =
        rem(duration, 60)
        |> Integer.to_string()
        |> String.pad_leading(2, "0")

      "#{div(duration, 60)}:#{seconds}"
    end)
  end
end
