defmodule Mix.Tasks.Xandra.Drop do
  @moduledoc false

  use Mix.Task

  def run(_) do
    Mix.Task.run("app.start")

    drop_keyspace()
  end

  defp drop_keyspace() do
    keyspace = XandraMigrator.cassandra_keyspace()

    Mix.shell().info("Dropping keyspace \"#{keyspace}\".")

    query = "DROP KEYSPACE IF EXISTS #{keyspace}"

    case Xandra.execute(:xandra, query, []) do
      {:ok,
       %Xandra.SchemaChange{
         effect: "DROPPED",
         options: %{keyspace: ^keyspace},
         target: "KEYSPACE",
         tracing_id: nil
       }} ->
        Mix.shell().info("Keyspace \"#{keyspace}\" was dropped.")

      {:ok, %Xandra.Void{tracing_id: nil}} ->
        Mix.shell().info("Keyspace \"#{keyspace}\" is not exists.")

      error ->
        Mix.raise("Cannot drop keyspace \"#{keyspace}\". Reason: #{inspect(error)}")
    end
  end
end
