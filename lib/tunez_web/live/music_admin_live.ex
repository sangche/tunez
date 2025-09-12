defmodule TunezWeb.MusicAdminLive do
  use TunezWeb, :live_view

  # P.146 To block a liveview from unauthenticated users
  on_mount {TunezWeb.LiveUserAuth, role_required: :admin}

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <div class="relative m-10">
        <.icon name="hero-bell-alert" class="w-8 h-8 bg-gray-400" />
        <span class="text-3xl px-2">This liveview is for Administrator only!</span>
      </div>
    </Layouts.app>
    """
  end
end
