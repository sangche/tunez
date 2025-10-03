defmodule Tunez.Music.Changes.MinutesToSeconds do
  use Ash.Resource.Change

  # With this callback, together with require_atomic? true in Track Resource action :update,
  # Ash will try to atomically update each track(just in case the data in memory is out of date),
  # leading to a classic n+1 query problem. PDF page 251. Performance issue.
  # So, if you don't need to ensure atomic update, set require_atomic? false,
  @impl true
  def atomic(changeset, opts, context) do
    {:ok, change(changeset, opts, context)}
  end

  @impl true
  def change(changeset, _opts, _context) do
    {:ok, duration} = Ash.Changeset.fetch_argument(changeset, :duration)

    with :ok <- ensure_valid_format(duration),
         :ok <- ensure_valid_value(duration) do
      changeset
      |> Ash.Changeset.change_attribute(:duration_seconds, to_seconds(duration))
    else
      {:error, :format} ->
        Ash.Changeset.add_error(changeset,
          field: :duration,
          message: "use MM:SS format"
        )

      {:error, :value} ->
        Ash.Changeset.add_error(changeset,
          field: :duration,
          message: "must be at least 1 second long"
        )
    end
  end

  defp ensure_valid_format(duration) do
    if String.match?(duration, ~r/^\d+:\d{2}$/) do
      :ok
    else
      {:error, :format}
    end
  end

  defp ensure_valid_value(v) when v in ["0:00", "00:00"], do: {:error, :value}
  defp ensure_valid_value(_value), do: :ok

  defp to_seconds(duration) do
    [minutes, seconds] = String.split(duration, ":", parts: 2)
    String.to_integer(minutes) * 60 + String.to_integer(seconds)
  end
end

# For example:
# Tunez.Music.Track |> Ash.Changeset.for_create(:create, %{duration: "00:00"})
# will pass valid_format, but won't valid_value,
# %Ash.Error.Changes.InvalidAttribute{
#       field: :duration,
#       message: "must be at least 1 second long",
#       value: nil,

# In case "000:00", pass valid_format and valid_value,
# but fail duration_seconds attribute constraint min:1 in Track Resource.
# Tunez.Music.Track |> Ash.Changeset.for_create(:create, %{duration: "000:00"})
# %Ash.Error.Changes.InvalidAttribute{
# field: :duration_seconds,
# message: "must be more than or equal to %{min}",
# value: 0,
