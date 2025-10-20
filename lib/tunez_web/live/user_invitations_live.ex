defmodule TunezWeb.UserInvitationsLive do
  use TunezWeb, :live_view
  # alias Tunez.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <TunezWeb.UserInvitationsLive.InviteNewUserForm.form actor={@current_user} />

      <Cinder.Table.table
        resource={Tunez.Music.Artist}
        actor={@current_user}
        id="music-artists-table"
        page_size={20}
      >
        <:col :let={row} label="Name" field="name" filter sort>
          {row.name}
        </:col>
        <:col :let={row} label="Biography" field="biography" filter sort>
          {row.biography}
        </:col>
        <:col :let={row} label="Previous Names" field="previous_names">{row.previous_names}</:col>
      </Cinder.Table.table>

      <Cinder.Table.table
        resource={Tunez.Accounts.User}
        actor={@current_user}
        page_size={20}
        id="user-invitations-table"
      >
        <:col :let={user} field="id" filter sort>{user.id}</:col>
        <:col :let={user} field="email" filter sort>{user.email}</:col>
        <:col :let={user} field="hashed_password" filter>{user.hashed_password}</:col>
        <:col :let={user} field="role" filter sort>{user.role}</:col>
      </Cinder.Table.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _sessions, socket) do
    {:ok,
     socket
     |> assign(:page_title, gettext("User Invitations"))}
  end
end

# https://medium.com/@lambert.kamaro/part-20-ash-framework-for-phoenix-developers-building-team-owner-invitations-for-adding-new-5319758b9a51
