defmodule ExturnWeb.TurnLive do
  use ExturnWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100 text-base-content">
      <!-- Neo-Brutalist Header -->
      <header class="w-full border-b-2 border-black bg-white mb-8">
        <div class="max-w-2xl mx-auto flex flex-col sm:flex-row items-center justify-between px-4 py-6 gap-2">
          <div class="flex items-center gap-3">
            <span class="font-black text-2xl tracking-tight uppercase">Exturn</span>
            <span class="badge badge-outline text-xs font-mono tracking-widest">
              ONE VOICE, ONE MOMENT
            </span>
          </div>
          <span class="text-xs font-mono text-black/60">Welcome, <b>{@name}</b></span>
        </div>
      </header>

      <main class="max-w-2xl mx-auto flex flex-col gap-8 px-4">
        <!-- Turn Management Card -->
        <section class="card card-border bg-white border-2 border-black shadow-none">
          <div class="card-body gap-4">
            <h2 class="card-title text-lg font-bold uppercase tracking-wider mb-2">Turn Control</h2>
            <div class="flex flex-wrap gap-3">
              <button
                class={"btn btn-neutral btn-dash font-bold uppercase px-6 " <> get_button_class(@user_status, @current_speaker, @name)}
                phx-click="toggle_talking"
                phx-value-name={@name}
                disabled={get_button_disabled(@user_status, @current_speaker, @name)}
              >
                {get_button_text(@user_status, @current_speaker, @name)}
              </button>
              <button
                :if={@current_speaker != nil}
                class="btn btn-neutral btn-outline font-bold uppercase px-6"
                phx-click="request_for_turn"
                disabled={@user_status in [:talking, :waiting] or @current_speaker == @name}
              >
                {get_request_button_text(@user_status)}
              </button>
            </div>

            <div
              :if={@current_speaker}
              class="alert alert-outline alert-info border-2 border-black mt-4"
            >
              <span class="font-bold uppercase">Now Speaking:</span>
              <span class="font-mono text-lg"><b>{@current_speaker}</b></span>
            </div>

            <div
              :if={length(@waiting_queue) > 0}
              class="alert alert-outline alert-warning border-2 border-black mt-2"
            >
              <span class="font-bold uppercase">Queue</span>
              <span class="font-mono text-xs">{Enum.join(@waiting_queue, " → ")}</span>
            </div>
          </div>
        </section>
        
    <!-- Participants Card -->
        <section class="card card-dash bg-white border-2 border-black shadow-none">
          <div class="card-body gap-4">
            <h3 class="card-title text-lg font-bold uppercase tracking-wider mb-2">
              Participants <span class="badge badge-outline font-mono">{@participant_count}</span>
            </h3>
            <ul id="online_users" phx-update="stream" class="flex flex-col gap-2">
              <li
                :for={{dom_id, %{id: id, metas: _metas}} <- @streams.presences}
                id={dom_id}
                class="flex items-center justify-between border-b border-black last:border-b-0 py-2 px-1"
              >
                <div class="flex items-center gap-3">
                  <span class="inline-block w-8 h-8 border-2 border-black bg-base-200 text-center font-mono font-bold text-lg leading-8">
                    {String.first(id) |> String.upcase()}
                  </span>
                  <span class="font-mono text-base">{id}</span>
                </div>
                <span class={"badge badge-outline font-mono text-xs " <> get_status_badge_class(id, @current_speaker, @waiting_queue)}>
                  {get_user_status_text(id, @current_speaker, @waiting_queue)}
                </span>
              </li>
            </ul>
          </div>
        </section>
      </main>
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
      |> assign(:participant_count, 0)

    socket =
      if connected?(socket) do
        ExturnWeb.Presence.track_user(params["name"], %{id: params["name"], status: "idle"})
        ExturnWeb.Presence.subscribe()
        Phoenix.PubSub.subscribe(Exturn.PubSub, "turn_management")
        presences = ExturnWeb.Presence.list_online_users()

        socket
        |> stream(:presences, presences)
        |> assign(:participant_count, length(presences))
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
    socket =
      socket
      |> stream_insert(:presences, presence)
      |> update(:participant_count, &(&1 + 1))

    {:noreply, socket}
  end

  def handle_info({ExturnWeb.Presence, {:leave, presence}}, socket) do
    socket =
      if presence.metas == [] do
        socket =
          socket
          |> stream_delete(:presences, presence)
          |> update(:participant_count, &max(&1 - 1, 0))

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

    socket
    |> stream(:presences, current_presences)
    |> assign(:participant_count, length(current_presences))
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
      current_speaker == username and user_status == :talking -> "btn-error btn-soft"
      current_speaker == nil and user_status == :idle -> "btn-success btn-soft"
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
      _ -> "Request to Speak"
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
      user_id == current_speaker -> "badge-success badge-soft"
      user_id in waiting_queue -> "badge-warning badge-soft"
      true -> "badge-ghost"
    end
  end

  defp get_user_indicator_class(user_id, current_speaker, waiting_queue) do
    cond do
      user_id == current_speaker ->
        "ring ring-success ring-offset-base-100 ring-offset-2 animate-pulse"

      user_id in waiting_queue ->
        "ring ring-warning ring-offset-base-100 ring-offset-2"

      true ->
        ""
    end
  end

  # New helper functions for enhanced UI
  defp get_loading_class(_user_status, _current_speaker, _username) do
    # Could add loading states based on conditions
    ""
  end

  defp get_show_loading(_user_status, _current_speaker, _username) do
    # For now, we don't show loading spinners
    # This could be enhanced to show loading during state transitions
    false
  end

  defp get_button_icon(user_status, current_speaker, username) do
    cond do
      current_speaker == username and user_status == :talking ->
        "M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15z M17 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2"

      current_speaker == nil and user_status == :idle ->
        "M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z"

      true ->
        "M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15z M15 9l6 6m0-6l-6 6"
    end
  end

  defp get_user_description(user_id, current_speaker, waiting_queue) do
    cond do
      user_id == current_speaker ->
        "Currently speaking"

      user_id in waiting_queue ->
        position = Enum.find_index(waiting_queue, &(&1 == user_id)) + 1
        "#{position}#{ordinal_suffix(position)} in speaking queue"

      true ->
        "Available to speak"
    end
  end

  defp ordinal_suffix(n) do
    case rem(n, 100) do
      11 ->
        "th"

      12 ->
        "th"

      13 ->
        "th"

      _ ->
        case rem(n, 10) do
          1 -> "st"
          2 -> "nd"
          3 -> "rd"
          _ -> "th"
        end
    end
  end
end
