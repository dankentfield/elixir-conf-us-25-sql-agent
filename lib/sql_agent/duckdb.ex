defmodule SqlAgent.DuckDB do
  @moduledoc """
  DuckDB connection manager with persistent database storage.
  """

  use GenServer
  require Logger

  @db_path "priv/duckdb/sql_agent.db"

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_connection do
    GenServer.call(__MODULE__, :get_connection)
  end

  def execute(query) do
    with {:ok, conn} <- get_connection(),
         {:ok, stmt} <- Duckdbex.prepare_statement(conn, query),
         {:ok, result_ref} <- Duckdbex.execute_statement(stmt) do
      result_ref
      |> Duckdbex.fetch_all()
      |> IO.inspect(label: "result")
      |> format_result()
    else
      {:error, reason} -> {:error, "Query failed: #{inspect(reason)}"}
    end
  end

  defp format_result(rows) when is_list(rows) do
    case rows do
      [] ->
        {:ok, "Query executed successfully. No rows returned."}

      [first_row | _] ->
        # Extract column names from the first row if it's a keyword list
        columns = extract_column_names(first_row)
        formatted = format_table(columns, rows)
        {:ok, formatted}
    end
  end

  defp format_result(result) do
    {:ok, "Query executed successfully. Result: #{inspect(result)}"}
  end

  defp extract_column_names(row) when is_list(row) do
    case row do
      # If it's a keyword list, extract keys as column names
      [{key, _} | _] when is_atom(key) ->
        Enum.map(row, fn {key, _} -> to_string(key) end)

      # Otherwise, generate generic column names
      _ ->
        row
        |> Enum.with_index()
        |> Enum.map(fn {_, idx} -> "column_#{idx + 1}" end)
    end
  end

  defp extract_column_names(_), do: ["value"]

  defp format_table(columns, rows) do
    # Extract values from rows (handle both keyword lists and regular lists)
    row_values = Enum.map(rows, &extract_row_values/1)

    # Calculate column widths
    column_widths =
      columns
      |> Enum.with_index()
      |> Enum.map(fn {col, idx} ->
        col_width = String.length(col)

        max_row_width =
          row_values
          |> Enum.map(fn row ->
            cell = Enum.at(row, idx) |> format_cell_value()
            String.length(cell)
          end)
          |> Enum.max(fn -> 0 end)

        max(col_width, max_row_width)
      end)

    # Format header
    header =
      columns
      |> Enum.with_index()
      |> Enum.map(fn {col, idx} ->
        String.pad_trailing(col, Enum.at(column_widths, idx))
      end)
      |> Enum.join(" | ")

    # Format separator
    separator =
      column_widths
      |> Enum.map(fn width -> String.duplicate("-", width) end)
      |> Enum.join(" | ")

    # Format rows
    formatted_rows =
      row_values
      |> Enum.map(fn row ->
        row
        |> Enum.with_index()
        |> Enum.map(fn {cell, idx} ->
          cell_str = format_cell_value(cell)
          String.pad_trailing(cell_str, Enum.at(column_widths, idx))
        end)
        |> Enum.join(" | ")
      end)

    [header, separator | formatted_rows]
    |> Enum.join("\n")
  end

  defp extract_row_values(row) when is_list(row) do
    case row do
      # If it's a keyword list, extract values
      [{_key, _value} | _] ->
        Enum.map(row, fn {_key, value} -> value end)

      # Otherwise, it's already a list of values
      _ ->
        row
    end
  end

  defp extract_row_values(row), do: [row]

  defp format_cell_value({{year, month, day}, {hour, minute, second, microsecond}}) 
       when is_integer(year) and is_integer(month) and is_integer(day) and 
            is_integer(hour) and is_integer(minute) and is_integer(second) and is_integer(microsecond) do
    # Format DuckDB timestamp as readable datetime
    "#{year}-#{pad_zero(month)}-#{pad_zero(day)} #{pad_zero(hour)}:#{pad_zero(minute)}:#{pad_zero(second)}.#{div(microsecond, 1000)}"
  end

  defp format_cell_value({year, month, day}) 
       when is_integer(year) and is_integer(month) and is_integer(day) do
    # Format DuckDB date
    "#{year}-#{pad_zero(month)}-#{pad_zero(day)}"
  end

  defp format_cell_value({hour, minute, second, microsecond}) 
       when is_integer(hour) and is_integer(minute) and is_integer(second) and is_integer(microsecond) do
    # Format DuckDB time
    "#{pad_zero(hour)}:#{pad_zero(minute)}:#{pad_zero(second)}.#{div(microsecond, 1000)}"
  end

  defp format_cell_value(tuple) when is_tuple(tuple) do
    # Handle any other tuple types by converting to string representation
    inspect(tuple)
  end

  defp format_cell_value(value) do
    to_string(value)
  end

  defp pad_zero(number) when is_integer(number) and number < 10, do: "0#{number}"
  defp pad_zero(number) when is_integer(number), do: to_string(number)
  defp pad_zero(value), do: inspect(value)

  @impl true
  def init(_opts) do
    # Ensure the directory exists
    @db_path
    |> Path.dirname()
    |> File.mkdir_p!()

    with {:ok, db} <- Duckdbex.open(@db_path),
         {:ok, conn} <- Duckdbex.connection(db),
         {:ok, stmt} <- Duckdbex.prepare_statement(conn, "SET autoinstall_known_extensions=1"),
         {:ok, _} <- Duckdbex.execute_statement(stmt),
         {:ok, stmt} <- Duckdbex.prepare_statement(conn, "SET autoload_known_extensions=1"),
         {:ok, _} <- Duckdbex.execute_statement(stmt) do
      Logger.info("DuckDB opened successfully at #{@db_path}")
      {:ok, %{db: db, conn: conn}}
    else
      {:error, reason} ->
        Logger.error("Failed to open DuckDB: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  @impl true
  def handle_call(:get_connection, _from, %{conn: conn} = state) do
    {:reply, {:ok, conn}, state}
  end

  @impl true
  def terminate(_reason, %{conn: conn}) do
    Duckdbex.release(conn)
  end
end
