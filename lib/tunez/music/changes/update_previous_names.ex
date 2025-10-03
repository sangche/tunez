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
  def atomic(_changeset, _opts, _context) do
    {:atomic,
     %{
       previous_names:
         {:atomic,
          expr(
            fragment(
              "array_remove(array_prepend(?, ?), ?)",
              name,
              previous_names,
              ^atomic_ref(:name)
            )
          )}
     }}
  end

  # array_remove(array_prepend('new_name', '{old_name2, old_name1}'), 'current_name')

  # Now, when 2 users change name concurrently, each get get through db update in sequence,
  # and both previous names are kept in db in the previous_names list.
  # So, the last update will be kept after previous updates in the previous_names list.
  # see Page 250 of PDF book
end
