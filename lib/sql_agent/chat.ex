defmodule SqlAgent.Chat do
  @moduledoc """
  The Chat context for handling chat messages and interactions.
  """

  import Ecto.Query, warn: false
  alias SqlAgent.Repo
  alias SqlAgent.Chat.Message
  alias SqlAgent.Chat.ChatRoom

  ## ChatRoom functions

  @doc """
  Gets a single chat room.
  """
  def get_chat_room!(id), do: Repo.get!(ChatRoom, id)

  @doc """
  Creates a chat room.
  """
  def create_chat_room(attrs \\ %{}) do
    %ChatRoom{}
    |> ChatRoom.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets or creates the most recent chat room for a user.
  """
  def get_or_create_chat_room_for_user(user_id) do
    case get_most_recent_chat_room_for_user(user_id) do
      nil ->
        create_chat_room(%{user_id: user_id, title: "Chat"})

      chat_room ->
        {:ok, chat_room}
    end
  end

  @doc """
  Gets the most recent chat room for a user.
  """
  def get_most_recent_chat_room_for_user(user_id) do
    ChatRoom
    |> where([c], c.user_id == ^user_id)
    |> order_by([c], desc: c.inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Creates a new chat room for a user with an optional title.
  """
  def create_new_chat_room_for_user(user_id, title \\ nil) do
    title = title || "Chat #{System.system_time(:second)}"
    create_chat_room(%{user_id: user_id, title: title})
  end

  ## Message functions

  @doc """
  Returns the list of messages for a chat room ordered by insertion time.
  """
  def list_messages_for_chat(chat_id) do
    Message
    |> where([m], m.chat_id == ^chat_id)
    |> order_by([m], asc: m.inserted_at)
    |> Repo.all()
  end

  @doc """
  Returns the list of messages ordered by insertion time.
  """
  def list_messages do
    Message
    |> order_by([m], asc: m.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single message.
  """
  def get_message!(id), do: Repo.get!(Message, id)

  @doc """
  Creates a message.
  """
  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a user message from the given content.
  """
  def create_user_message(content, user_id, chat_id) do
    create_message(%{
      content: String.trim(content),
      sender_type: "user",
      user_id: user_id,
      chat_id: chat_id
    })
  end

  @doc """
  Creates an assistant message with the given content.
  """
  def create_assistant_message(content \\ "hello world", chat_id) do
    create_message(%{
      content: content,
      sender_type: "assistant",
      chat_id: chat_id
    })
  end

  @doc """
  Handles sending a user message and triggering an assistant response.
  Returns {:ok, user_message} or {:error, reason}.
  """
  def send_message(content, user_id, chat_id) do
    with {:ok, trimmed_content} <- validate_content(content),
         {:ok, user_message} <- create_user_message(trimmed_content, user_id, chat_id),
         {:ok, _job} <- SqlAgent.Workers.MessageWorker.enqueue_assistant_message(chat_id) do
      {:ok, user_message}
    end
  end

  defp validate_content(content) do
    case String.trim(content) do
      "" -> {:error, :empty_message}
      trimmed -> {:ok, trimmed}
    end
  end

  ## Tool Call Message functions

  @doc """
  Creates a tool call message.
  """
  def create_tool_call_message(attrs \\ %{}) do
    attrs = Map.put(attrs, :sender_type, "tool_call")
    create_message(attrs)
  end

  @doc """
  Saves a tool call with its parameters for the given chat as a message.
  This is called before the assistant executes a tool.
  """
  def save_tool_call(chat_id, tool_name, args) when is_map(args) and not is_nil(chat_id) do
    metadata = %{
      tool_name: tool_name,
      parameters: args,
      result: nil,
      executed_at: DateTime.utc_now()
    }

    attrs = %{
      metadata: metadata,
      chat_id: chat_id,
      sender_type: "tool_call"
    }

    case create_tool_call_message(attrs) do
      {:ok, tool_call_message} ->
        Phoenix.PubSub.broadcast(
          SqlAgent.PubSub,
          "chat:#{chat_id}",
          {:tool_call_started, tool_call_message}
        )

        {:ok, tool_call_message}

      error ->
        error
    end
  end

  def save_tool_call(chat_id, _tool_name, args) when is_nil(chat_id) do
    require Logger
    Logger.warning("Attempted to save tool call with nil chat_id. Args: #{inspect(args)}")
    {:error, :nil_chat_id}
  end

  def save_tool_call(chat_id, _tool_name, args) when not is_map(args) do
    require Logger

    Logger.warning(
      "Attempted to save tool call with non-map args. chat_id: #{chat_id}, args: #{inspect(args)}"
    )

    {:error, :invalid_args}
  end

  @doc """
  Updates a tool call message with its result after execution.
  """
  def update_tool_call(tool_call_message, result) do
    result_text =
      case result do
        {:ok, text} -> text
        {:error, error} -> "Error: #{error}"
        text when is_binary(text) -> text
        other -> inspect(other)
      end

    updated_metadata = Map.put(tool_call_message.metadata, :result, result_text)
    changeset = Message.changeset(tool_call_message, %{metadata: updated_metadata})

    case Repo.update(changeset) do
      {:ok, updated_message} ->
        # Broadcast that the tool call completed
        Phoenix.PubSub.broadcast(
          SqlAgent.PubSub,
          "chat:#{tool_call_message.chat_id}",
          {:tool_call_completed, updated_message}
        )

        {:ok, updated_message}

      error ->
        error
    end
  end

  @doc """
  Returns the list of tool call messages for a chat room ordered by insertion time.
  """
  def list_tool_calls_for_chat(chat_id) do
    Message
    |> where([m], m.chat_id == ^chat_id and m.sender_type == "tool_call")
    |> order_by([m], asc: m.inserted_at)
    |> Repo.all()
  end

  @doc """
  Returns only chat messages (not tool calls) for a chat room.
  """
  def list_chat_messages_for_chat(chat_id) do
    Message
    |> where([m], m.chat_id == ^chat_id and m.sender_type in ["user", "assistant"])
    |> order_by([m], asc: m.inserted_at)
    |> Repo.all()
  end
end
