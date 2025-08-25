defmodule SqlAgent.Workers.MessageWorker do
  @moduledoc """
  Worker for processing assistant messages asynchronously using LLM.
  """
  use Oban.Worker, queue: :messages, max_attempts: 3

  alias SqlAgent.Chat
  alias SqlAgent.LLM

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"chat_id" => chat_id}}) do
    with {:ok, response_content} <- generate_llm_response(chat_id),
         {:ok, message} <- Chat.create_assistant_message(response_content, chat_id) do
      # Broadcast the message to the chat room
      Phoenix.PubSub.broadcast(
        SqlAgent.PubSub,
        "chat:#{chat_id}",
        {:new_message, message}
      )

      :ok
    else
      {:error, reason} ->
        # Log the error and fallback to a simple message
        require Logger
        Logger.error("LLM generation failed for chat #{chat_id}: #{inspect(reason)}")

        # Create fallback response
        case Chat.create_assistant_message(
               "I apologize, but I'm having trouble generating a response right now. Please try again.",
               chat_id
             ) do
          {:ok, message} ->
            Phoenix.PubSub.broadcast(
              SqlAgent.PubSub,
              "chat:#{chat_id}",
              {:new_message, message}
            )

            :ok

          {:error, fallback_reason} ->
            # Broadcast error if even fallback fails
            Phoenix.PubSub.broadcast(
              SqlAgent.PubSub,
              "chat:#{chat_id}",
              {:assistant_error, fallback_reason}
            )
            {:error, fallback_reason}
        end
    end
  end

  @doc """
  Enqueues a job to create an assistant message.
  """
  def enqueue_assistant_message(chat_id, opts \\ []) do
    %{chat_id: chat_id}
    |> new(opts)
    |> Oban.insert()
  end

  # Private function to generate LLM response
  defp generate_llm_response(chat_id) do
    messages = Chat.list_messages_for_chat(chat_id)

    # Configure LLM options
    llm_opts = [
      system_message: """
      You are an agentic DuckDB SQL database assistant. You have access to a run_sql tool that allows you to execute SQL queries against the database.

      Your role is to be proactive and persistent in exploring the database to achieve user objectives. When a user asks a question:

      1. ALWAYS start by exploring the database structure using SQL queries to understand what tables, columns, and data are available
      2. Use multiple queries as needed to thoroughly understand the data before answering
      3. Keep querying and exploring until you have enough information to provide a complete answer
      4. Don't give up easily - try different approaches, check for variations in naming, case sensitivity, or data types
      5. Always provide the reasoning for each query you run using the 'reason' parameter

      Key behaviors:
      - Be curious and thorough in your database exploration
      - Use the run_sql tool extensively to gather information
      - Don't assume table structures - always verify with queries
      - If one approach doesn't work, try alternative queries or table names
      - Only conclude something is impossible after exhaustive exploration
      - Show your work by explaining what you discovered through each query

      Remember: Your strength is in being persistent and methodical in database exploration. Use the run_sql tool as your primary way to understand and work with the database.

      Return content in markdown format.
      All database data should be formatted in a table in markdown format.
      Normal messages should be in markdown format.
      """
    ]

    # Generate response using LangChain
    LLM.generate_response(messages, chat_id, llm_opts)
  end
end
