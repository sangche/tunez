defmodule Tunez.Music.Changes.UpdatePreviousNames do
  use Ash.Resource.Change

  # should be wrapped in hooks such as Ash.Changeset.before_action or Ash.Changeset.after_action.
  # See page 56 of PDF book

  # [warning] Changeset has already been validated for action :update.
  # For safety, we prevent any changes after that point because they will bypass validations or other action logic.. To proceed anyway,
  # you can use `force_change_attribute/3`. However, you should prefer a pattern like the below, which makes
  # any custom changes *before* calling the action.

  # Resource
  # |> Ash.Changeset.new()
  # |> Ash.Changeset.change_attribute(...)
  # |> Ash.Changeset.for_create(...)

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_action(changeset, fn changeset ->
      # IO.inspect(changeset,
      #   label: "changeset given inside change in module gets called only before action"
      # )

      # below are done in memory, not in DB
      # so, no need to use Ash.Query.load to load :previous_names
      # because it is already loaded in the changeset data when the artist was loaded
      # in the mount, before calling the update action.
      # so race condition can happen if multiple updates happen simultaneously
      # because the changes are done in memory, not in DB
      # so, the last update will overwrite previous updates
      # see Page 250 of PDF book
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
