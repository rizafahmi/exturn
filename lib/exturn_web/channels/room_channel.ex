defmodule ExturnWeb.RoomChannel do
  use ExturnWeb, :channel
  alias ExturnWeb.Presence

  @impl true
  def join("room:lobby", %{"name" => name}, socket) do
    send(self(), :after_join)

    socket =
      socket
      |> assign(:name, name)

    {:ok, socket}
  end

  def join("room:" <> room_id, _message, socket) do
    dbg("Joining room: #{room_id}")
    {:ok, socket}
  end

  # def join("room:lobby", payload, socket) do
  #   if authorized?(payload) do
  #     {:ok, socket}
  #   else
  #     {:error, %{reason: "unauthorized"}}
  #   end
  # end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (room:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _} =
      Presence.track(socket, socket.assigns.name, %{
        online_at: inspect(System.system_time(:second))
      })

    push(socket, "presence_state", Presence.list(socket))

    {:noreply, socket}
  end

  # Add authorization logic here as required.
  # defp authorized?(_payload) do
  #   true
  # end
end
