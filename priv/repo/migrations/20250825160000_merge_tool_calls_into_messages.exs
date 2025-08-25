defmodule SqlAgent.Repo.Migrations.MergeToolCallsIntoMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :metadata, :map
    end
  end
end
