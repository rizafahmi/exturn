defmodule ExturnWeb.TurnLive do
  use ExturnWeb, :live_view

  def render(assigns) do
    ~H"""
    <div>
      <h1>It's My Turn!</h1>
      <button phx-click="request_for_turn">Ask for a turn</button>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_event("request_for_turn", _params, socket) do
    dbg("Request for turn")
    {:noreply, socket}
  end
end
