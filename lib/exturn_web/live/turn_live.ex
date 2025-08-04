defmodule ExturnWeb.TurnLive do
  use ExturnWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-base-200 to-base-300">
      <!-- Beautiful Header -->
      <div class="bg-base-100 shadow-lg border-b border-base-300">
        <div class="container mx-auto px-6 py-4">
          <div class="flex items-center justify-between">
            <div class="flex items-center space-x-3">
              <div class="avatar placeholder">
                <div class="bg-primary text-primary-content rounded-full w-12">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-6 w-6"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M17 8h2a2 2 0 012 2v6a2 2 0 01-2 2h-2v4l-4-4H9a3 3 0 01-3-3v-1m7-4V5a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2h2v4l.586-.586z"
                    />
                  </svg>
                </div>
              </div>
              <div>
                <h1 class="text-2xl font-bold text-base-content">Exturn</h1>
                <p class="text-sm text-base-content/70">One Voice, One Moment</p>
              </div>
            </div>
            <div class="flex items-center space-x-2">
              <div class="badge badge-soft badge-success">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-3 w-3 mr-1"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
                Online
              </div>
              <div class="text-sm text-base-content/60">Welcome, <strong>{@name}</strong></div>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Main Content -->
      <div class="container mx-auto p-6 space-y-6">
        <!-- Turn Management Card -->
        <div class="card card-border bg-base-100 shadow-2xl hover:shadow-3xl transition-all duration-300">
          <div class="card-body">
            <div class="flex items-center justify-between mb-6">
              <h2 class="card-title text-xl">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-6 w-6 text-primary"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z"
                  />
                </svg>
                Speaking Controls
              </h2>
              <div class="stats stats-horizontal shadow-md">
                <div class="stat py-2 px-4">
                  <div class="stat-value text-sm text-primary">{@participant_count}</div>
                  <div class="stat-title text-xs">Online</div>
                </div>
                <div class="stat py-2 px-4">
                  <div class="stat-value text-sm text-warning">{length(@waiting_queue)}</div>
                  <div class="stat-title text-xs">In Queue</div>
                </div>
              </div>
            </div>

            <div class="space-y-4">
              <div class="flex flex-wrap gap-4">
                <button
                  class={"btn btn-lg #{get_button_class(@user_status, @current_speaker, @name)} #{get_loading_class(@user_status, @current_speaker, @name)} transition-all duration-200 hover:scale-105"}
                  phx-click="toggle_talking"
                  phx-value-name={@name}
                  disabled={get_button_disabled(@user_status, @current_speaker, @name)}
                >
                  <span
                    :if={get_show_loading(@user_status, @current_speaker, @name)}
                    class="loading loading-spinner loading-sm"
                  >
                  </span>
                  <svg
                    :if={!get_show_loading(@user_status, @current_speaker, @name)}
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-5 w-5"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d={get_button_icon(@user_status, @current_speaker, @name)}
                    />
                  </svg>
                  {get_button_text(@user_status, @current_speaker, @name)}
                </button>

                <button
                  :if={@current_speaker != nil}
                  class="btn btn-lg btn-soft btn-warning transition-all duration-200 hover:scale-105"
                  phx-click="request_for_turn"
                  disabled={@user_status in [:talking, :waiting] or @current_speaker == @name}
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-5 w-5"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                  {get_request_button_text(@user_status)}
                </button>
              </div>
              
    <!-- Current Speaker Alert -->
              <div :if={@current_speaker} class="alert alert-soft alert-info shadow-lg animate-pulse">
                <div class="flex items-center">
                  <div class="avatar placeholder mr-3">
                    <div class="bg-info text-info-content rounded-full w-10 animate-bounce">
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        class="h-5 w-5"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z"
                        />
                      </svg>
                    </div>
                  </div>
                  <div>
                    <h3 class="font-bold">Now Speaking</h3>
                    <div class="text-sm opacity-90">
                      <strong>{@current_speaker}</strong> has the floor
                    </div>
                  </div>
                </div>
              </div>
              
    <!-- Queue Alert -->
              <div :if={length(@waiting_queue) > 0} class="alert alert-soft alert-warning shadow-lg">
                <div class="flex items-center">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-6 w-6 shrink-0 mr-3"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                  <div class="flex-1">
                    <h3 class="font-bold">Speaking Queue</h3>
                    <div class="text-sm opacity-90">
                      <span class="badge badge-warning badge-sm mr-2">{length(@waiting_queue)}</span>
                      {Enum.join(@waiting_queue, " → ")}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Participants Card -->
        <div class="card card-border bg-base-100 shadow-2xl hover:shadow-3xl transition-all duration-300">
          <div class="card-body">
            <div class="flex items-center justify-between mb-4">
              <h3 class="card-title">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-6 w-6 text-primary"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
                  />
                </svg>
                Participants ({@participant_count})
              </h3>
            </div>

            <div class="grid gap-3">
              <div
                :for={{dom_id, %{id: id, metas: _metas}} <- @streams.presences}
                id={dom_id}
                class="flex items-center justify-between p-4 bg-gradient-to-r from-base-200 to-base-100 rounded-xl hover:shadow-lg transition-all duration-200 hover:scale-[1.02] border border-base-300"
              >
                <div class="flex items-center space-x-4">
                  <div class={"avatar placeholder #{get_user_indicator_class(id, @current_speaker, @waiting_queue)}"}>
                    <div class="bg-gradient-to-br from-primary to-secondary text-primary-content rounded-full w-12 h-12 shadow-lg">
                      <span class="text-lg font-bold">{String.first(id) |> String.upcase()}</span>
                    </div>
                  </div>
                  <div>
                    <span class="font-semibold text-lg text-base-content">{id}</span>
                    <div class="text-sm text-base-content/60">
                      {get_user_description(id, @current_speaker, @waiting_queue)}
                    </div>
                  </div>
                </div>
                <div class="flex items-center space-x-2">
                  <div class={"badge badge-lg #{get_status_badge_class(id, @current_speaker, @waiting_queue)} shadow-md"}>
                    {get_user_status_text(id, @current_speaker, @waiting_queue)}
                  </div>
                  <div :if={id == @current_speaker} class="indicator">
                    <span class="indicator-item badge badge-success badge-xs animate-pulse"></span>
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="h-6 w-6 text-success"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z"
                      />
                    </svg>
                  </div>
                </div>
              </div>
            </div>
          </div>
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
