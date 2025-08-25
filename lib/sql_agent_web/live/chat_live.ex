defmodule SqlAgentWeb.ChatLive do
  use SqlAgentWeb, :live_view

  alias SqlAgent.Chat

  # Helper function to render markdown content
  defp render_markdown(content) do
    options = %Earmark.Options{
      code_class_prefix: "language-"
    }
    case Earmark.as_html(content, options) do
      {:ok, html, _} -> raw(html)
      {:error, _, _} -> content
    end
  end

  on_mount {SqlAgentWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    {:ok, chat_room} = Chat.get_or_create_chat_room_for_user(current_user.id)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(SqlAgent.PubSub, "chat:#{chat_room.id}")
    end

    messages = Chat.list_messages_for_chat(chat_room.id)

    {:ok, assign(socket,
      messages: messages,
      message: "",
      chat_room: chat_room,
      current_user: current_user,
      loading: false
    )}
  end

  @impl true
  def handle_event("send_message", %{"message" => message}, socket) do
    current_user = socket.assigns.current_user
    chat_room = socket.assigns.chat_room

    socket = assign(socket, loading: true)

    case Chat.send_message(message, current_user.id, chat_room.id) do
      {:ok, user_message} ->
        Phoenix.PubSub.broadcast(SqlAgent.PubSub, "chat:#{chat_room.id}", {:new_message, user_message})

        # Reload all messages from the database
        messages = Chat.list_messages_for_chat(chat_room.id)
        {:noreply, assign(socket, messages: messages, message: "", loading: true)}

      {:error, :empty_message} ->
        socket = put_flash(socket, :error, "Message cannot be empty")
        {:noreply, assign(socket, message: "", loading: false)}

      {:error, reason} ->
        socket = put_flash(socket, :error, "Failed to send message: #{inspect(reason)}")
        {:noreply, assign(socket, message: "", loading: false)}
    end
  end

  @impl true
  def handle_event("update_message", %{"message" => message}, socket) do
    {:noreply, assign(socket, message: message)}
  end

  @impl true
  def handle_event("new_chat", _params, socket) do
    current_user = socket.assigns.current_user

    case Chat.create_new_chat_room_for_user(current_user.id) do
      {:ok, new_chat_room} ->
        # Unsubscribe from old chat room
        Phoenix.PubSub.unsubscribe(SqlAgent.PubSub, "chat:#{socket.assigns.chat_room.id}")

        # Subscribe to new chat room
        Phoenix.PubSub.subscribe(SqlAgent.PubSub, "chat:#{new_chat_room.id}")

        # Get messages for new chat room (should be empty)
        messages = Chat.list_messages_for_chat(new_chat_room.id)

        {:noreply, assign(socket,
          chat_room: new_chat_room,
          messages: messages,
          message: "",
          loading: false
        )}

      {:error, _reason} ->
        socket = put_flash(socket, :error, "Failed to create new chat room")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    # Only stop loading when we receive an assistant message (response)
    loading = if message.sender_type == "assistant", do: false, else: socket.assigns.loading
    chat_room_id = socket.assigns.chat_room.id
    {:noreply, assign(socket,
      messages: Chat.list_messages_for_chat(chat_room_id),
      loading: loading
    )}
  end

  @impl true
  def handle_info({:assistant_error, _reason}, socket) do
    # Stop loading if there's an error generating the assistant response
    {:noreply, assign(socket, loading: false)}
  end

  @impl true
  def handle_info({:tool_call_started, _tool_call}, socket) do
    # Reload messages to show the new tool call started
    chat_room_id = socket.assigns.chat_room.id
    {:noreply, assign(socket, messages: Chat.list_messages_for_chat(chat_room_id))}
  end

  @impl true
  def handle_info({:tool_call_completed, _tool_call}, socket) do
    # Reload messages to show the completed tool call result
    chat_room_id = socket.assigns.chat_room.id
    {:noreply, assign(socket, messages: Chat.list_messages_for_chat(chat_room_id))}
  end


  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-4 max-w-6xl max-h-screen flex flex-col">
      <div class="chat-container bg-base-100 rounded-lg shadow-lg flex-1 flex flex-col min-h-0">
        <!-- Header -->
        <div class="bg-primary text-primary-content p-4 rounded-t-lg flex justify-between items-center">
          <div>
            <h1 class="text-2xl font-bold">SQL Agent</h1>
            <p class="opacity-80">Welcome! Start chatting with everyone.</p>
          </div>
          <button
            phx-click="new_chat"
            class="btn btn-sm btn-outline btn-primary-content"
            disabled={@loading}
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
            </svg>
            New Chat
          </button>
        </div>

        <!-- Messages -->
        <div class="messages p-4 flex-1 overflow-y-auto bg-base-50" id="messages" phx-hook="ScrollToBottom">
          <div :if={@messages == []} class="text-center text-base-content/60 mt-8">
            <div class="text-4xl mb-2">💬</div>
            <p>No messages yet. Be the first to say hello!</p>
          </div>

          <div :for={message <- @messages} class={[
            "chat mb-2",
            if(message.sender_type == "user", do: "chat-end", else: "chat-start")
          ]}>
            <!-- Regular chat message -->
            <div :if={message.sender_type in ["user", "assistant"]} class={[
              "chat-bubble",
              if(message.sender_type == "user", do: "chat-bubble-primary", else: "chat-bubble-secondary"),
              if(message.sender_type == "assistant", do: "prose prose-sm max-w-none", else: "")
            ]}>
              <%= if message.sender_type == "assistant" do %>
                <%= render_markdown(message.content) %>
              <% else %>
                <%= message.content %>
              <% end %>
            </div>

            <!-- Tool call message -->
            <div :if={message.sender_type == "tool_call"} class="chat-bubble chat-bubble-accent">
              <div class="flex items-center gap-2 mb-2">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"/>
                </svg>
                <strong>Running SQL Query</strong>
                <span :if={is_nil(get_in(message.metadata, ["result"]))} class="loading loading-spinner loading-xs"></span>
                <span :if={not is_nil(get_in(message.metadata, ["result"]))} class="text-success">✓</span>
              </div>
              <div class="text-sm text-white mb-2">
                <strong>Reason:</strong> <%= get_in(message.metadata, ["parameters", "reason"]) || "No reason provided" %>
              </div>
              <div class="text-sm text-primary font-mono bg-base-300 p-2 rounded">
                <%= get_in(message.metadata, ["parameters", "query"]) || "No query provided" %>
              </div>
              <div :if={get_in(message.metadata, ["result"])} class="mt-2">
                <div class="text-sm text-white mb-1"><strong>Result:</strong></div>
                <div class="text-xs text-primary font-mono bg-base-300 p-2 rounded max-h-32 overflow-y-auto">
                  <%= get_in(message.metadata, ["result"]) %>
                </div>
              </div>
            </div>

            <div class="chat-footer opacity-50 text-xs">
              <%= case message.sender_type do %>
                <% "user" -> %>
                  You · <%= Calendar.strftime(message.inserted_at, "%H:%M") %>
                <% "tool_call" -> %>
                  Tool Call · <%= Calendar.strftime(message.inserted_at, "%H:%M") %>
                <% "assistant" -> %>
                  Assistant · <%= Calendar.strftime(message.inserted_at, "%H:%M") %>
              <% end %>
            </div>
          </div>

          <!-- Loading Spinner -->
          <div :if={@loading} class="flex justify-center items-center p-4">
            <div class="flex items-center gap-2 text-base-content/60">
              <span class="loading loading-spinner loading-sm"></span>
              <span class="text-sm">Assistant is typing...</span>
            </div>
          </div>
        </div>

        <!-- Input Form -->
        <div class="p-4 bg-base-200 rounded-b-lg flex-shrink-0">
          <form phx-submit="send_message" class="flex gap-2">
            <input
              type="text"
              name="message"
              value={@message}
              phx-change="update_message"
              placeholder="Type your message..."
              class="input input-bordered flex-1"
              autocomplete="off"
            />
            <button
              type="submit"
              class={["btn btn-primary", @loading && "loading"]}
              disabled={String.trim(@message) == "" || @loading}
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"/>
              </svg>
              Send
            </button>
          </form>
        </div>
      </div>
    </div>
    """
  end

end
