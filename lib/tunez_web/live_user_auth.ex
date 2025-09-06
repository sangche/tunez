defmodule TunezWeb.LiveUserAuth do
  @moduledoc """
  Helpers for authenticating users in LiveViews.
  """

  import Phoenix.Component
  use TunezWeb, :verified_routes

  # This is used for nested liveviews to fetch the current user.
  # To use, place the following at the top of that liveview:
  # on_mount {TunezWeb.LiveUserAuth, :current_user}
  def on_mount(:current_user, _params, session, socket) do
    {:cont, AshAuthentication.Phoenix.LiveSession.assign_new_resources(socket, session)}
  end

  def on_mount(:live_user_optional, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:cont, socket}
    else
      {:cont, assign(socket, :current_user, nil)}
    end
  end

  # only after email confirmation is done
  def on_mount(:live_user_required, _params, _session, socket) do
    if socket.assigns[:current_user] do
      if socket.assigns[:current_user].confirmed_at do
        IO.inspect(socket.assigns[:current_user].confirmed_at, label: "current_user")
        {:cont, socket}
      else
        # {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/auth/new?activity=confirm_new_user")}
        {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/artists/new")}
      end
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/sign-in")}
    end
  end

  def on_mount(:live_no_user, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/")}
    else
      {:cont, assign(socket, :current_user, nil)}
    end
  end
end
