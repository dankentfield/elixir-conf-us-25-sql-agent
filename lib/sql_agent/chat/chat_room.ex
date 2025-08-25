defmodule SqlAgent.Chat.ChatRoom do
  @moduledoc """
  ChatRoom schema for organizing conversations.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias SqlAgent.Accounts.User
  alias SqlAgent.Chat.Message

  schema "chats" do
    field :title, :string
    
    belongs_to :user, User
    has_many :messages, Message, foreign_key: :chat_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(chat_room, attrs) do
    chat_room
    |> cast(attrs, [:title, :user_id])
    |> validate_required([:user_id])
    |> validate_length(:title, max: 200)
    |> foreign_key_constraint(:user_id)
  end
end