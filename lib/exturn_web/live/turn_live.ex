defmodule ExturnWeb.TurnLive do
  use ExturnWeb, :live_view

  def render(assigns) do
    ~H"""
    <ul id="online_users" phx-update="stream">
      <li :for={{dom_id, %{id: id, metas: metas}} <- @streams.presences} id={dom_id}>
        {id} ({length(metas)})
      </li>
    </ul>
    """
  end

  def mount(params, _session, socket) do
    socket = stream(socket, :presences, [])

    socket =
      if connected?(socket) do
        ExturnWeb.Presence.track_user(params["name"], %{id: params["name"]})
        ExturnWeb.Presence.subscribe()
        stream(socket, :presences, ExturnWeb.Presence.list_online_users())
      else
        socket
      end

    {:ok, socket}
  end

  def handle_event("request_for_turn", _params, socket) do
    dbg("Request for turn")
    {:noreply, socket}
  end

  def handle_info({ExturnWeb.Presence, {:join, presence}}, socket) do
    {:noreply, stream_insert(socket, :presences, presence)}
  end

  def handle_info({ExturnWeb.Presence, {:leave, presence}}, socket) do
    if presence.metas == [] do
      {:noreply, stream_delete(socket, :presences, presence.id)}
    else
      {:noreply, stream_insert(socket, :presences, presence.id)}
    end
  end
end
