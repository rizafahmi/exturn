defmodule ExturnWeb.TurnLive do
  use ExturnWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="p-6 space-y-4">
      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <h2 class="card-title">Video Conference - Turn Management</h2>

          <div class="space-y-3">
            <div class="flex flex-wrap gap-3">
              <button
                class={"btn #{get_button_class(@user_status, @current_speaker, @name)}"}
                phx-click="toggle_talking"
                phx-value-name={@name}
                disabled={get_button_disabled(@user_status, @current_speaker, @name)}
              >
                {get_button_text(@user_status, @current_speaker, @name)}
              </button>

              <button
                :if={@current_speaker != nil}
                class="btn btn-outline"
                phx-click="request_for_turn"
                disabled={@user_status in [:talking, :waiting] or @current_speaker == @name}
              >
                {get_request_button_text(@user_status)}
              </button>
            </div>

            <div :if={@current_speaker} class="alert alert-info">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                class="stroke-current shrink-0 w-6 h-6"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                >
                </path>
              </svg>
              <span><strong>{@current_speaker}</strong> is currently speaking</span>
            </div>

            <div :if={length(@waiting_queue) > 0} class="alert alert-warning">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                class="stroke-current shrink-0 w-6 h-6"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16c-.77.833.192 2.5 1.732 2.5z"
                >
                </path>
              </svg>
              <div>
                <div class="font-medium">Queue ({length(@waiting_queue)} waiting):</div>
                <div class="text-sm opacity-75">
                  {Enum.join(@waiting_queue, " → ")}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <h3 class="card-title">Participants</h3>
          <ul id="online_users" phx-update="stream" class="space-y-2">
            <li
              :for={{dom_id, %{id: id, metas: _metas}} <- @streams.presences}
              id={dom_id}
              class="flex items-center justify-between p-3 bg-base-200 rounded-lg"
            >
              <div class="flex items-center space-x-3">
                <div class={"avatar placeholder #{get_user_indicator_class(id, @current_speaker, @waiting_queue)}"}>
                  <div class="bg-neutral text-neutral-content rounded-full w-8">
                    <span class="text-xs">{String.first(id)}</span>
                  </div>
                </div>
                <span class="font-medium">{id}</span>
              </div>
              <div class={"badge #{get_status_badge_class(id, @current_speaker, @waiting_queue)}"}>
                {get_user_status_text(id, @current_speaker, @waiting_queue)}
              </div>
            </li>
          </ul>
        </div>
      </div>
    </div>
    """
  end

  def handle_params(%{"name" => name}, _uri, socket) do
    socket =
      socket
      |> assign(:name, name)
      |> assign(:user_status, :idle)

    {:noreply, socket}
  end

  def mount(params, _session, socket) do
    socket =
      socket
      |> stream(:presences, [])
      |> assign(:current_speaker, nil)
      |> assign(:waiting_queue, [])
      |> assign(:user_status, :idle)

    socket =
      if connected?(socket) do
        ExturnWeb.Presence.track_user(params["name"], %{id: params["name"], status: "idle"})
        ExturnWeb.Presence.subscribe()
        Phoenix.PubSub.subscribe(Exturn.PubSub, "turn_management")
        stream(socket, :presences, ExturnWeb.Presence.list_online_users())
      else
        socket
      end

    {:ok, socket}
  end

  def handle_event("toggle_talking", %{"name" => name}, socket) do
    cond do
      # User wants to start talking and no one is currently speaking
      socket.assigns.current_speaker == nil and socket.assigns.user_status == :idle ->
        socket = start_talking(name, socket)
        socket = refresh_presence_stream(socket)
        broadcast_state_change(socket)
        {:noreply, socket}

      # Current speaker wants to stop talking
      socket.assigns.current_speaker == name and socket.assigns.user_status == :talking ->
        socket = stop_talking(name, socket)
        socket = refresh_presence_stream(socket)
        broadcast_state_change(socket)
        {:noreply, socket}

      # User is not allowed to talk (someone else is speaking)
      true ->
        {:noreply, socket}
    end
  end

  def handle_event("request_for_turn", _params, socket) do
    name = socket.assigns.name

    cond do
      # User is already in queue or talking
      socket.assigns.user_status in [:waiting, :talking] ->
        {:noreply, socket}

      # User is current speaker
      socket.assigns.current_speaker == name ->
        {:noreply, socket}

      # Add user to queue
      name not in socket.assigns.waiting_queue ->
        socket = add_to_queue(name, socket)
        socket = refresh_presence_stream(socket)
        broadcast_state_change(socket)
        {:noreply, socket}

      true ->
        {:noreply, socket}
    end
  end

  def handle_info({ExturnWeb.Presence, {:join, presence}}, socket) do
    {:noreply, stream_insert(socket, :presences, presence)}
  end

  def handle_info({ExturnWeb.Presence, {:leave, presence}}, socket) do
    socket =
      if presence.metas == [] do
        socket = stream_delete(socket, :presences, presence)

        # Handle speaker or queue member leaving
        cond do
          socket.assigns.current_speaker == presence.id ->
            # Current speaker left, promote next in queue
            socket =
              socket
              |> assign(:current_speaker, nil)
              |> update_user_status_if_current_user(presence.id, :idle)

            advance_queue(socket)

          presence.id in socket.assigns.waiting_queue ->
            # Remove from queue
            socket
            |> assign(:waiting_queue, List.delete(socket.assigns.waiting_queue, presence.id))
            |> update_user_status_if_current_user(presence.id, :idle)

          true ->
            socket
        end
      else
        stream_insert(socket, :presences, presence)
      end

    socket = refresh_presence_stream(socket)
    broadcast_state_change(socket)
    {:noreply, socket}
  end

  def handle_info(
        {:state_change, %{current_speaker: current_speaker, waiting_queue: waiting_queue}},
        socket
      ) do
    user_status = determine_user_status(socket.assigns.name, current_speaker, waiting_queue)

    socket =
      socket
      |> assign(:current_speaker, current_speaker)
      |> assign(:waiting_queue, waiting_queue)
      |> assign(:user_status, user_status)
      |> refresh_presence_stream()

    {:noreply, socket}
  end

  # State management functions
  defp start_talking(name, socket) do
    socket
    |> assign(:current_speaker, name)
    |> assign(:user_status, :talking)
  end

  defp stop_talking(_name, socket) do
    socket =
      socket
      |> assign(:current_speaker, nil)
      |> assign(:user_status, :idle)

    advance_queue(socket)
  end

  defp add_to_queue(name, socket) do
    new_queue = socket.assigns.waiting_queue ++ [name]

    socket
    |> assign(:waiting_queue, new_queue)
    |> assign(:user_status, :waiting)
  end

  defp advance_queue(socket) do
    case socket.assigns.waiting_queue do
      [next_speaker | remaining_queue] ->
        socket
        |> assign(:current_speaker, next_speaker)
        |> assign(:waiting_queue, remaining_queue)
        |> update_user_status_if_current_user(next_speaker, :talking)

      [] ->
        socket
    end
  end

  defp update_user_status_if_current_user(socket, user_id, status) do
    if socket.assigns.name == user_id do
      assign(socket, :user_status, status)
    else
      socket
    end
  end

  defp determine_user_status(username, current_speaker, waiting_queue) do
    cond do
      username == current_speaker -> :talking
      username in waiting_queue -> :waiting
      true -> :idle
    end
  end

  defp broadcast_state_change(socket) do
    Phoenix.PubSub.broadcast(
      Exturn.PubSub,
      "turn_management",
      {:state_change,
       %{
         current_speaker: socket.assigns.current_speaker,
         waiting_queue: socket.assigns.waiting_queue
       }}
    )
  end

  defp refresh_presence_stream(socket) do
    # Re-stream all presences to force UI update when state changes
    current_presences = ExturnWeb.Presence.list_online_users()
    stream(socket, :presences, current_presences)
  end

  # UI Helper functions
  defp get_button_text(user_status, current_speaker, username) do
    cond do
      current_speaker == username and user_status == :talking -> "Stop Talking"
      current_speaker == nil and user_status == :idle -> "Start Talking"
      current_speaker != nil and current_speaker != username -> "Someone Speaking"
      true -> "Start Talking"
    end
  end

  defp get_button_class(user_status, current_speaker, username) do
    cond do
      current_speaker == username and user_status == :talking -> "btn-error"
      current_speaker == nil and user_status == :idle -> "btn-success"
      true -> "btn-disabled"
    end
  end

  defp get_button_disabled(user_status, current_speaker, username) do
    not ((current_speaker == username and user_status == :talking) or
           (current_speaker == nil and user_status == :idle))
  end

  defp get_request_button_text(user_status) do
    case user_status do
      :waiting -> "In Queue"
      :talking -> "Speaking"
      _ -> "Request Turn"
    end
  end

  defp get_user_status_text(user_id, current_speaker, waiting_queue) do
    cond do
      user_id == current_speaker ->
        "Speaking"

      user_id in waiting_queue ->
        "Waiting (##{Enum.find_index(waiting_queue, &(&1 == user_id)) + 1})"

      true ->
        "Idle"
    end
  end

  defp get_status_badge_class(user_id, current_speaker, waiting_queue) do
    cond do
      user_id == current_speaker -> "badge-success"
      user_id in waiting_queue -> "badge-warning"
      true -> "badge-ghost"
    end
  end

  defp get_user_indicator_class(user_id, current_speaker, waiting_queue) do
    cond do
      user_id == current_speaker -> "ring ring-success ring-offset-base-100 ring-offset-2"
      user_id in waiting_queue -> "ring ring-warning ring-offset-base-100 ring-offset-2"
      true -> ""
    end
  end
end
