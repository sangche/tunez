defmodule Tunez.Music.Changes.UpdatePreviousNames do
  use Ash.Resource.Change

  # should be wrapped in hooks such as Ash.Changeset.before_action or Ash.Changeset.after_action.
  # See page 56 of PDF book

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_action(changeset, fn changeset ->
      IO.inspect(changeset,
        label: "changeset given inside change in module gets called only before action"
      )

      new_name = Ash.Changeset.get_attribute(changeset, :name)
      previous_name = Ash.Changeset.get_data(changeset, :name)
      previous_names = Ash.Changeset.get_data(changeset, :previous_names)

      names =
        [previous_name | previous_names]
        |> Enum.uniq()
        |> Enum.reject(fn name -> name == new_name end)

      Ash.Changeset.change_attribute(changeset, :previous_names, names)
    end)
  end
end
