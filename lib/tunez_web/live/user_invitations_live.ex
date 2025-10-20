defmodule TunezWeb.UserInvitationsLive do
  use TunezWeb, :live_view
  # alias Tunez.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Cinder.Table.table
      resource={Tunez.Accounts.User}
      actor={@current_user}
      id="user-invitations-table"
      page_size={20}
    >
      <:col :let={row} label="Email" field="email" filter sort>
        {row.email}
      </:col>
      <:col :let={row} label="ID" field="id" filter sort>
        {row.id}
      </:col>
      <:col :let={row} label="Role" field="role">{row.role}</:col>
    </Cinder.Table.table>

    <Cinder.Table.table
      resource={Tunez.Accounts.User}
      actor={@current_user}
      page_size={20}
      id="user-invitations-table2"
    >
      <:col :let={user} field="id" filter sort>{user.id}</:col>
      <:col :let={user} field="email" filter sort>{user.email}</:col>
      <:col :let={user} field="hashed_password" filter>{user.hashed_password}</:col>
      <:col :let={user} field="role" filter sort>{user.role}</:col>
    </Cinder.Table.table>
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
