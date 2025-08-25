defmodule SqlAgent.LLM do
  @moduledoc """
  LLM module for handling language model interactions using LangChain.
  """

  alias LangChain.Message
  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI

  @doc """
  Maps database messages to LangChain messages.

  Takes a list of `SqlAgent.Chat.Message` structs and converts them to
  `LangChain.Message` structs with appropriate roles.
  """
  def map_messages_to_langchain(db_messages) do
    Enum.map(db_messages, &map_message_to_langchain/1)
  end

  defp map_message_to_langchain(%{sender_type: "user", content: content}) do
    Message.new_user!(content)
  end

  defp map_message_to_langchain(%{sender_type: "assistant", content: content}) do
    Message.new_assistant!(content)
  end

  defp map_message_to_langchain(%{content: content}) do
    Message.new_user!(content)
  end

  @doc """
  Creates a message chain from database messages.

  Takes a list of database messages, converts them to LangChain format,
  and creates an LLMChain ready for processing.
  """
  def create_message_chain(db_messages, chat_id, opts \\ []) do
    langchain_messages =
      map_messages_to_langchain(db_messages) |> IO.inspect(label: "langchain_messages")

    system_messages =
      case Keyword.get(opts, :system_message) do
        nil -> [Message.new_system!("You are a helpful SQL assistant.")]
        msg -> [Message.new_system!(msg)]
      end

    LLMChain.new!(%{
      llm:
        ChatOpenAI.new!(%{
          model: Keyword.get(opts, :model, "gpt-5"),
          stream: false
        }),
      custom_context: %{
        chat_id: chat_id
      }
    })
    |> LLMChain.add_messages(system_messages ++ langchain_messages)
    |> LLMChain.add_tools([SqlAgent.Tools.RunSql.new()])
  end

  @doc """
  Runs the message chain to generate a response.

  Takes an LLMChain and executes it to get the assistant's response.
  """
  def run_chain(chain) do
    LLMChain.run(chain, mode: :while_needs_response)
  end

  @doc """
  Convenience function to generate a response from database messages.

  Takes database messages, creates a chain, and runs it to get a response.
  """
  def generate_response(db_messages, chat_id, opts \\ []) do
    with chain <- create_message_chain(db_messages, chat_id, opts),
         {:ok, updated_chain} <- run_chain(chain),
         {:ok, content} <- LangChain.Utils.ChainResult.to_string(updated_chain) do
      {:ok, content}
    else
      {:error, _, reason} ->
        {:error, reason}
    end
  end
end
