defmodule TunezWeb.EmailConfirmLive do
  use TunezWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <div class="relative m-10">
        <.icon name="hero-bell-alert" class="w-8 h-8 bg-gray-400" />
        <span class="text-3xl px-2">Please confirm your email to continue!</span>
      </div>
    </Layouts.app>
    """
  end
end
