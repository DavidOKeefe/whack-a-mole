defmodule WhackAMoleWeb.GameLive do
  use WhackAMoleWeb, :live_view

  @grid_size 16
  @game_duration 30

  @difficulty_settings %{
    easy:   %{spawn_ms: 2500, visible_ms: 3500, label: "Easy",   emoji: "🐢"},
    medium: %{spawn_ms: 1000, visible_ms: 1200, label: "Medium", emoji: "🐇"},
    hard:   %{spawn_ms: 600,  visible_ms: 750,  label: "Hard",   emoji: "⚡"}
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       grid: List.duplicate(:empty, @grid_size),
       score: 0,
       time_left: @game_duration,
       game_state: :idle,
       difficulty: :easy
     )}
  end

  @impl true
  def handle_event("set_difficulty", %{"level" => level}, socket) do
    {:noreply, assign(socket, difficulty: String.to_existing_atom(level))}
  end

  def handle_event("start", _params, socket) do
    settings = @difficulty_settings[socket.assigns.difficulty]

    if connected?(socket) do
      schedule_tick()
      schedule_mole_spawn(settings.spawn_ms)
    end

    {:noreply,
     assign(socket,
       grid: List.duplicate(:empty, @grid_size),
       score: 0,
       time_left: @game_duration,
       game_state: :playing
     )}
  end

  def handle_event("whack", %{"index" => index_str}, %{assigns: %{game_state: :playing}} = socket) do
    index = String.to_integer(index_str)

    if Enum.at(socket.assigns.grid, index) == :mole do
      new_grid = List.replace_at(socket.assigns.grid, index, :empty)
      {:noreply, assign(socket, grid: new_grid, score: socket.assigns.score + 1)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("whack", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_info(:tick, %{assigns: %{game_state: :playing, time_left: 1}} = socket) do
    {:noreply,
     assign(socket,
       time_left: 0,
       game_state: :finished,
       grid: List.duplicate(:empty, @grid_size)
     )}
  end

  def handle_info(:tick, %{assigns: %{game_state: :playing}} = socket) do
    schedule_tick()
    {:noreply, assign(socket, time_left: socket.assigns.time_left - 1)}
  end

  def handle_info(:tick, socket), do: {:noreply, socket}

  def handle_info(:spawn_mole, %{assigns: %{game_state: :playing}} = socket) do
    settings = @difficulty_settings[socket.assigns.difficulty]
    schedule_mole_spawn(settings.spawn_ms)
    index = Enum.random(0..(@grid_size - 1))

    if Enum.at(socket.assigns.grid, index) == :empty do
      new_grid = List.replace_at(socket.assigns.grid, index, :mole)
      Process.send_after(self(), {:hide_mole, index}, settings.visible_ms)
      {:noreply, assign(socket, grid: new_grid)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(:spawn_mole, socket), do: {:noreply, socket}

  def handle_info({:hide_mole, index}, socket) do
    if Enum.at(socket.assigns.grid, index) == :mole do
      new_grid = List.replace_at(socket.assigns.grid, index, :empty)
      {:noreply, assign(socket, grid: new_grid)}
    else
      {:noreply, socket}
    end
  end

  defp schedule_tick, do: Process.send_after(self(), :tick, 1000)
  defp schedule_mole_spawn(ms), do: Process.send_after(self(), :spawn_mole, ms)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center min-h-screen bg-green-100 py-10">
      <h1 class="text-5xl font-bold text-green-800 mb-6">🐭 Whack-a-Mole!</h1>

      <div class="flex gap-10 mb-6">
        <div class="text-2xl font-semibold text-green-900">
          Score: <span class="text-green-600 font-bold"><%= @score %></span>
        </div>
        <div class="text-2xl font-semibold text-green-900">
          Time:
          <span class={if @time_left <= 5, do: "text-red-600 font-bold", else: "text-green-600 font-bold"}>
            <%= @time_left %>s
          </span>
        </div>
      </div>

      <%= if @game_state in [:idle, :finished] do %>
        <div class="mb-6 text-center">
          <%= if @game_state == :finished do %>
            <p class="text-4xl font-bold text-green-800 mb-2">Time's up! 🎉</p>
            <p class="text-2xl text-green-700 mb-4">
              You whacked <strong><%= @score %></strong> moles!
              <%= cond do %>
                <% @score >= 20 -> %>🏆 Amazing!
                <% @score >= 10 -> %>⭐ Great job!
                <% true -> %>Keep practicing!
              <% end %>
            </p>
          <% end %>

          <p class="text-xl font-semibold text-green-800 mb-3">Choose difficulty:</p>
          <div class="flex gap-3 mb-6">
            <%= for {level, settings} <- [easy: %{label: "Easy", emoji: "🐢"}, medium: %{label: "Medium", emoji: "🐇"}, hard: %{label: "Hard", emoji: "⚡"}] do %>
              <button
                phx-click="set_difficulty"
                phx-value-level={level}
                class={[
                  "px-6 py-3 text-xl font-bold rounded-xl border-4 transition-all",
                  if(@difficulty == level,
                    do: "bg-green-600 text-white border-green-800 scale-105 shadow-lg",
                    else: "bg-white text-green-800 border-green-400 hover:border-green-600"
                  )
                ]}
              >
                <%= settings.emoji %> <%= settings.label %>
              </button>
            <% end %>
          </div>

          <button
            phx-click="start"
            class="px-10 py-4 bg-green-600 text-white text-2xl font-bold rounded-2xl shadow-lg hover:bg-green-700 active:scale-95 transition-all"
          >
            <%= if @game_state == :finished, do: "Play Again! 🎮", else: "Start Game! 🎮" %>
          </button>
        </div>
      <% end %>

      <div class="grid grid-cols-4 gap-4 p-6 bg-green-700 rounded-3xl shadow-xl">
        <%= for {cell, index} <- Enum.with_index(@grid) do %>
          <button
            phx-click="whack"
            phx-value-index={index}
            class={[
              "w-24 h-24 rounded-full text-5xl flex items-center justify-center transition-all duration-150 shadow-inner",
              if(cell == :mole, do: "bg-amber-400 scale-110 shadow-lg", else: "bg-amber-900 hover:bg-amber-800")
            ]}
          >
            <%= if cell == :mole, do: "🐭", else: "" %>
          </button>
        <% end %>
      </div>
    </div>
    """
  end
end
