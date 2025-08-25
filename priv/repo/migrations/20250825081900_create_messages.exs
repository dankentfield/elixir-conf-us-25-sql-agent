defmodule SqlAgent.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :content, :text, null: true
      add :sender_type, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:messages, [:inserted_at])
    create index(:messages, [:sender_type])
  end
end
