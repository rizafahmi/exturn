defmodule ExturnWeb.TurnLive do
  use ExturnWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100 text-base-content">
      <main class="max-w-2xl mx-auto flex flex-col gap-4 sm:gap-8 px-3 sm:px-4 py-4 sm:py-8">
        <!-- Turn Management Card -->
        <section class="card card-border bg-white border-2 border-black shadow-none">
          <div class="card-body gap-3 sm:gap-4">
            <h2 class="card-title text-base sm:text-lg font-bold uppercase tracking-wider mb-1 sm:mb-2 flex-col sm:flex-row items-start sm:items-center gap-2">
              <span>Turn Control</span>
              <span class="badge badge-outline font-mono text-xs normal-case">@{@name}</span>
            </h2>
            <div class="mobile-button-grid sm:flex sm:flex-wrap sm:gap-3">
              <button
                class={"btn btn-neutral btn-dash font-bold uppercase px-4 sm:px-6 text-sm sm:text-base " <> get_button_class(@user_status, @current_speaker, @name)}
                phx-click="toggle_talking"
                phx-value-name={@name}
                disabled={get_button_disabled(@user_status, @current_speaker, @name)}
              >
                <span class="sm:hidden">
                  {get_button_text_short(@user_status, @current_speaker, @name)}
                </span>
                <span class="hidden sm:inline">
                  {get_button_text(@user_status, @current_speaker, @name)}
                </span>
              </button>
              <button
                :if={@current_speaker != nil}
                class="btn btn-neutral btn-outline font-bold uppercase px-4 sm:px-6 text-sm sm:text-base"
                phx-click="request_for_turn"
                disabled={@user_status in [:talking, :waiting] or @current_speaker == @name}
              >
                <span class="sm:hidden">{get_request_button_text_short(@user_status)}</span>
                <span class="hidden sm:inline">{get_request_button_text(@user_status)}</span>
              </button>
            </div>

            <div
              :if={@current_speaker}
              class={
                if @current_speaker == @name do
                  "alert bg-warning border-4 border-error text-error-content mt-2 sm:mt-4 flex flex-col sm:flex-row items-center gap-2 sm:gap-4 animate-pulse shadow-lg text-center sm:text-left"
                else
                  "alert alert-outline alert-info border-2 border-black mt-2 sm:mt-4 flex flex-col sm:flex-row items-center gap-2 sm:gap-4 text-center sm:text-left"
                end
              }
            >
              <span :if={@current_speaker == @name} class="text-2xl sm:text-3xl">🎤</span>
              <div class="flex flex-col sm:flex-row items-center gap-1 sm:gap-2">
                <span class={
                  if @current_speaker == @name,
                    do: "font-black uppercase tracking-wider text-lg sm:text-2xl",
                    else: "font-bold uppercase text-sm sm:text-base"
                }>
                  Now Speaking:
                </span>
                <span class={
                  if @current_speaker == @name,
                    do: "font-mono text-xl sm:text-3xl font-black",
                    else: "font-mono text-base sm:text-lg"
                }>
                  <%= if @current_speaker == @name do %>
                    You
                  <% else %>
                    {@current_speaker}
                  <% end %>
                </span>
              </div>
            </div>

            <div
              :if={length(@waiting_queue) > 0}
              class="alert alert-outline alert-warning border-2 border-black mt-2 flex flex-col sm:flex-row items-center gap-2 text-center sm:text-left"
            >
              <span class="font-bold uppercase text-sm">Queue</span>
              <span class="font-mono text-xs break-all">{Enum.join(@waiting_queue, " → ")}</span>
            </div>
          </div>
        </section>
        
    <!-- Participants Card -->
        <section class="card card-dash bg-white border-2 border-black shadow-none">
          <div class="card-body gap-3 sm:gap-4">
            <h3 class="card-title text-base sm:text-lg font-bold uppercase tracking-wider mb-1 sm:mb-2 flex flex-col sm:flex-row items-start sm:items-center gap-2">
              <span>Participants</span>
              <span class="badge badge-outline font-mono text-xs">{@participant_count}</span>
            </h3>
            <ul id="online_users" phx-update="stream" class="flex flex-col gap-1 sm:gap-2">
              <li
                :for={{dom_id, %{id: id, metas: _metas}} <- @streams.presences}
                id={dom_id}
                class="participant-item flex items-center justify-between border-b border-black last:border-b-0 py-3 sm:py-2 px-2 sm:px-1 min-h-16 sm:min-h-0"
              >
                <div class="flex items-center gap-3 min-w-0 flex-1">
                  <span class="participant-avatar inline-block w-10 h-10 sm:w-8 sm:h-8 border-2 border-black bg-base-200 text-center font-mono font-bold text-lg sm:text-lg leading-10 sm:leading-8 flex-shrink-0">
                    {String.first(id) |> String.upcase()}
                  </span>
                  <span class="font-mono text-sm sm:text-base truncate">{id}</span>
                </div>
                <span class={"badge badge-outline font-mono text-xs px-2 py-1 flex-shrink-0 " <> get_status_badge_class(id, @current_speaker, @waiting_queue)}>
                  <span class="sm:hidden">
                    {get_user_status_text_short(id, @current_speaker, @waiting_queue)}
                  </span>
                  <span class="hidden sm:inline">
                    {get_user_status_text(id, @current_speaker, @waiting_queue)}
                  </span>
                </span>
              </li>
            </ul>
          </div>
        </section>
        
    <!-- Leave Session Button -->
        <section class="flex justify-center">
          <button
            class="btn btn-outline btn-error font-bold uppercase px-6 sm:px-8 text-sm sm:text-base"
            phx-click="exit_session"
          >
            <span class="sm:hidden">Leave</span>
            <span class="hidden sm:inline">Leave Session</span>
          </button>
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

  def handle_event("exit_session", _params, socket) do
    # Clean up user presence before navigating away
    if connected?(socket) do
      ExturnWeb.Presence.untrack(self(), "online_users", socket.assigns.name)
    end

    {:noreply, push_navigate(socket, to: "/")}
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

  defp get_button_text_short(user_status, current_speaker, username) do
    cond do
      current_speaker == username and user_status == :talking -> "Stop"
      current_speaker == nil and user_status == :idle -> "Start"
      current_speaker != nil and current_speaker != username -> "Busy"
      true -> "Start"
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

  defp get_request_button_text_short(user_status) do
    case user_status do
      :waiting -> "Queued"
      :talking -> "Speaking"
      _ -> "Request"
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

  defp get_user_status_text_short(user_id, current_speaker, waiting_queue) do
    cond do
      user_id == current_speaker ->
        "📢"

      user_id in waiting_queue ->
        "##{Enum.find_index(waiting_queue, &(&1 == user_id)) + 1}"

      true ->
        "💤"
    end
  end

  defp get_status_badge_class(user_id, current_speaker, waiting_queue) do
    cond do
      user_id == current_speaker -> "badge-success badge-soft"
      user_id in waiting_queue -> "badge-warning badge-soft"
      true -> "badge-ghost"
    end
  end
end
