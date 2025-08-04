defmodule ExturnWeb.TurnLive do
  use ExturnWeb, :live_view

  def render(assigns) do
    ~H"""
    <div>
      <button class="btn btn-primary" phx-click="toggle_talking" phx-value-name={@name}>
        {@button}
      </button>
      <button class="btn btn-neutral" phx-click="request_for_turn">Request for turn</button>
    </div>
    <ul id="online_users" phx-update="stream">
      <li :for={{dom_id, %{id: id, metas: metas}} <- @streams.presences} id={dom_id}>
        {id} {(metas |> hd())[:status]}
      </li>
    </ul>
    """
  end

  def handle_params(%{"name" => name}, _uri, socket) do
    socket =
      socket
      |> assign(:name, name)

    {:noreply, socket}
  end

  def mount(params, _session, socket) do
    socket =
      socket
      |> stream(:presences, [])
      |> assign(:button, "Start Talking")

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

  def handle_event("toggle_talking", %{"name" => name}, socket) do
    updated_socket =
      case socket.assigns.button do
        "Start Talking" ->
          handle_start_talking(name, socket)

        "Stop Talking" ->
          handle_stop_talking(name, socket)
      end

    # Update the status of the user who is talking
    ExturnWeb.Presence.update_status(name, "is talking...")
    dbg(ExturnWeb.Presence.list_online_users())
    # Update the status of all other users to 'not talking'
    for {user_id, _presence} <- ExturnWeb.Presence.list_online_users() do
      if user_id != name do
        ExturnWeb.Presence.update_status(user_id, "stopped talking")
      end
    end

    dbg(updated_socket.assigns.button)

    {:noreply, updated_socket}
  end

  def handle_event("talking", _params, socket) do
    dbg("Value is empty")
    {:noreply, socket}
  end

  def handle_event("request_for_turn", _params, socket) do
    dbg("Request for turn")
    {:noreply, socket}
  end

  def handle_info({ExturnWeb.Presence, {:join, presence}}, socket) do
    {:noreply, stream_insert(socket, :presences, presence)}
  end

  def handle_info({ExturnWeb.Presence, {:leave, presence}}, socket) do
    dbg("Presence leave event: #{inspect(presence)}")

    if presence.metas == [] do
      {:noreply, stream_delete(socket, :presences, presence.id)}
    else
      {:noreply, stream_insert(socket, :presences, presence)}
    end
  end

  defp handle_start_talking(name, socket) do
    socket =
      socket
      |> assign(:button, "Stop Talking")

    dbg(socket.assigns.button)
    # ExturnWeb.Presence.update_status(name, "is talking...")
    socket
  end

  defp handle_stop_talking(name, socket) do
    socket =
      socket
      |> assign(:button, "Start Talking")

    # ExturnWeb.Presence.update_status(name, "stopped talking")
    socket
  end
end
