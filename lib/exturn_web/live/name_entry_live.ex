defmodule ExturnWeb.NameEntryLive do
  use ExturnWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100 text-base-content flex items-center justify-center p-4">
      <main class="w-full max-w-md">
        <!-- Header Section -->
        <div class="text-center mb-8">
          <h1 class="text-4xl font-black uppercase tracking-wider mb-2">Turn Control</h1>

        </div>

        <!-- Name Entry Card -->
        <section class="card bg-white border-4 border-black shadow-none">
          <div class="card-body gap-6">
            <h2 class="card-title text-xl font-bold uppercase tracking-wider text-center justify-center">
              Enter Your Name
            </h2>

            <.form for={@form} phx-submit="join_room" phx-change="validate" class="space-y-4">
              <div class="form-control">
                <.input
                  field={@form[:name]}
                  type="text"
                  placeholder="Your name"
                  class="input input-bordered border-2 border-black focus:border-black focus:ring-0 font-mono text-lg"
                  autocomplete="off"
                  phx-debounce="300"
                />
                <div class="label" :if={@errors[:name]}>
                  <span class="label-text-alt text-error font-bold uppercase">
                    {@errors[:name]}
                  </span>
                </div>
              </div>

              <button
                type="submit"
                class="btn btn-neutral w-full font-bold uppercase tracking-wider text-lg border-2 border-black"
                disabled={@errors != %{}}
              >
                Join Room
              </button>
            </.form>

            <!-- Info Section -->
            <div class="alert alert-outline border-2 border-black">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-6 h-6">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
              </svg>
              <span class="text-sm font-mono">
                Enter a name to join the room
              </span>
            </div>
          </div>
        </section>
      </main>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:form, to_form(%{"name" => ""}, as: :user))
      |> assign(:errors, %{})

    {:ok, socket}
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    name = Map.get(user_params, "name", "")
    errors = validate_name(name)

    socket =
      socket
      |> assign(:form, to_form(user_params, as: :user))
      |> assign(:errors, errors)

    {:noreply, socket}
  end

  def handle_event("join_room", %{"user" => %{"name" => name}}, socket) do
    name = String.trim(name)
    errors = validate_name(name)

    if errors == %{} do
      {:noreply, push_navigate(socket, to: ~p"/online/#{name}")}
    else
      socket =
        socket
        |> assign(:form, to_form(%{"name" => name}, as: :user))
        |> assign(:errors, errors)

      {:noreply, socket}
    end
  end

  defp validate_name(name) do
    name = String.trim(name)
    errors = %{}

    errors =
      if name == "" do
        Map.put(errors, :name, "Name is required")
      else
        errors
      end

    errors =
      if String.length(name) > 50 do
        Map.put(errors, :name, "Name must be 50 characters or less")
      else
        errors
      end

    errors =
      if name != "" and not Regex.match?(~r/^[a-zA-Z0-9\s\-_]+$/, name) do
        Map.put(errors, :name, "Only letters, numbers, spaces, hyphens, and underscores allowed")
      else
        errors
      end

    errors
  end

end
