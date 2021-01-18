defmodule Mix.Tasks.Xandra.Create do
  @moduledoc false

  use Mix.Task

  def run(_) do
    Mix.Task.run("app.start")
    XandraMigrator.run_xandra()

    create_keyspace()
    create_migrations_table()
  end

  defp create_keyspace() do
    keyspace = XandraMigrator.cassandra_keyspace()

    Mix.shell().info("Creating keyspace \"#{keyspace}\".")

    query =
      "CREATE KEYSPACE IF NOT EXISTS #{keyspace} " <>
        "WITH replication = {'class': 'SimpleStrategy', 'replication_factor': '1'}  AND durable_writes = true"

    case Xandra.execute(:xandra, query, []) do
      {:ok,
       %Xandra.SchemaChange{
         effect: "CREATED",
         options: %{keyspace: ^keyspace},
         target: "KEYSPACE",
         tracing_id: nil
       }} ->
        Mix.shell().info("Keyspace \"#{keyspace}\" was created.")

      {:ok, %Xandra.Void{tracing_id: nil}} ->
        Mix.shell().info("Keyspace \"#{keyspace}\" is already exists.")

      error ->
        Mix.raise("Cannot create keyspace \"#{keyspace}\". Reason: #{inspect(error)}")
    end
  end

  defp create_migrations_table() do
    keyspace = XandraMigrator.cassandra_keyspace()

    Mix.shell().info("Creating \"schema_migrations\" table.")

    query =
      "CREATE TABLE IF NOT EXISTS #{keyspace}.schema_migrations ( " <>
        "version bigint, " <> "inserted_at timestamp, " <> "PRIMARY KEY (version)" <> ")"

    case Xandra.execute(:xandra, query, []) do
      {:ok,
       %Xandra.SchemaChange{
         effect: "CREATED",
         options: %{keyspace: ^keyspace, subject: "schema_migrations"},
         target: "TABLE",
         tracing_id: nil
       }} ->
        Mix.shell().info("Table \"schema_migrations\" was created.")

      {:ok, %Xandra.Void{tracing_id: nil}} ->
        Mix.shell().info("Table \"schema_migrations\" is already exists.")

      error ->
        Mix.raise("Cannot create table \"schema_migrations\". Reason: #{inspect(error)}")
    end
  end
end
