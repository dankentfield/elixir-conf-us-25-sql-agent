defmodule SqlAgent.Repo.Migrations.AddAssociationsToMessages do
  use Ecto.Migration

  def up do
    alter table(:messages) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :chat_id, references(:chats, on_delete: :delete_all), null: false
    end

    create index(:messages, [:user_id])
    create index(:messages, [:chat_id])
  end

  def down do
    drop index(:messages, [:user_id])
    drop index(:messages, [:chat_id])

    alter table(:messages) do
      remove :user_id
      remove :chat_id
    end
  end
end
