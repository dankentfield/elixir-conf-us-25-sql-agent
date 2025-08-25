defmodule SqlAgent.Tools.RunSql do
  @moduledoc """
  A LangChain function tool for executing SQL queries against DuckDB.
  """

  alias LangChain.Function

  @doc """
  Creates a LangChain Function for executing SQL queries.
  """
  def new() do
    Function.new!(%{
      name: "run_sql",
      description:
        "Execute a SQL query against the database. Use this when you need to query, insert, update, or delete data.",
      parameters_schema: %{
        type: "object",
        properties: %{
          query: %{
            type: "string",
            description: "The SQL query to execute"
          },
          reason: %{
            type: "string",
            description:
              "Explain why you are running this SQL query and what you expect to learn or accomplish"
          }
        },
        required: ["query", "reason"]
      },
      function: fn args, %{ chat_id: chat_id } ->
        require Logger
        Logger.info("RunSql tool called with chat_id: #{inspect(chat_id)}")
        Logger.info("RunSql tool called with args: #{inspect(args)}")

        # Save tool call before execution
        case SqlAgent.Chat.save_tool_call(chat_id, "run_sql", args) do
          {:ok, tool_call} ->
            # Execute the query
            result = execute_sql_query(args)

            # Update tool call with result
            SqlAgent.Chat.update_tool_call(tool_call, result)

            result

          {:error, _reason} ->
            # If we can't save the tool call, still execute the query
            execute_sql_query(args)
        end
      end
    })
  end

  defp execute_sql_query(args) do
    query = Map.get(args, "query")
    reason = Map.get(args, "reason")

    case SqlAgent.DuckDB.execute(query) do
      {:ok, result} ->
        response = """
        Reason: #{reason}

        Query: #{query}

        Result:
        #{result}
        """

        {:ok, response}

      {:error, error_msg} ->
        response = """
        Reason: #{reason}

        Query: #{query}

        Error: #{error_msg}
        """

        {:ok, response}
    end
  end
end
