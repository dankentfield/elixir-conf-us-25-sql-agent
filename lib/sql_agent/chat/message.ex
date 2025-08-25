defmodule SqlAgent.Chat.Message do
  @moduledoc """
  Message schema for chat messages.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias SqlAgent.Accounts.User
  alias SqlAgent.Chat.ChatRoom

  @sender_types ~w(user assistant tool_call)

  schema "messages" do
    field :content, :string
    field :sender_type, :string
    field :metadata, :map

    belongs_to :user, User
    belongs_to :chat, ChatRoom, foreign_key: :chat_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :sender_type, :user_id, :chat_id, :metadata])
    |> validate_required([:sender_type, :chat_id])
    |> validate_inclusion(:sender_type, @sender_types)
    |> validate_content_or_metadata()
    |> validate_length(:content, min: 1, max: 5000)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:chat_id)
  end

  # Validate that content is present for user/assistant messages, metadata for tool_call
  defp validate_content_or_metadata(changeset) do
    sender_type = get_field(changeset, :sender_type)
    content = get_field(changeset, :content)
    metadata = get_field(changeset, :metadata)

    case sender_type do
      "tool_call" ->
        if is_nil(metadata) do
          add_error(changeset, :metadata, "is required for tool_call messages")
        else
          changeset
        end
      _ ->
        if is_nil(content) or String.trim(content) == "" do
          add_error(changeset, :content, "is required for #{sender_type} messages")
        else
          changeset
        end
    end
  end

  @doc """
  Returns the list of valid sender types.
  """
  def sender_types, do: @sender_types

  @doc """
  Returns true if the message is a tool call.
  """
  def tool_call?(%__MODULE__{sender_type: "tool_call"}), do: true
  def tool_call?(%__MODULE__{}), do: false

  @doc """
  Returns true if the message is a regular chat message.
  """
  def chat_message?(%__MODULE__{sender_type: sender_type}) when sender_type in ["user", "assistant"], do: true
  def chat_message?(%__MODULE__{}), do: false
end