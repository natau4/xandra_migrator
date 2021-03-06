defmodule XandraMigrator do
  @moduledoc false

  alias XandraMigrator.SchemaMigrations
  alias XandraMigrator.XandraModels.SchemaMigration

  def cassandra_keyspace() do
    Application.get_env(:xandra_launcher, :xandra) |> Keyword.get(:keyspace)
  end

  def migrate() do
    IO.puts("Migrations running")

    path = migrations_path!()
    migration_files = File.ls!(path)

    current_version = SchemaMigrations.max_version!()

    new_migration_files =
      migration_files
      |> Enum.map(fn file ->
        Path.join([path, file]) |> extract_migration_info()
      end)
      |> Enum.filter(fn {version, _name, _file_path} ->
        current_version == nil || version > current_version
      end)
      |> Enum.sort_by(fn {version, _name, _file_path} ->
        version
      end)

    if Enum.empty?(new_migration_files), do: IO.puts("No one new migration was found.")

    run_migration(new_migration_files)
  end

  defp migrations_path!() do
    path = Path.join([File.cwd!(), "priv", "xandra", "migrations"])

    if !File.exists?(path) || !File.dir?(path) do
      raise XandraMigrator.MigrationError, "Expected to exist directory #{path} for migrations"
    end

    path
  end

  defp extract_migration_info(file) do
    base = Path.basename(file)

    case Integer.parse(Path.rootname(base)) do
      {integer, "_" <> name} -> {integer, name, file}
      _ -> nil
    end
  end

  defp run_migration([]) do
    IO.puts("Migrations completed")
  end

  defp run_migration([{version, _name, file_path} | tail]) do
    try do
      [{module_name, _}] = Code.compile_file(file_path)
      :ok = apply(module_name, :up, [])

      {:ok, %SchemaMigration{}} =
        SchemaMigration.new(%{version: version, inserted_at: System.os_time(:millisecond)})

      IO.puts("Migration #{file_path} was completed")
    rescue
      error -> IO.puts("Error for migration #{version}: #{inspect(error)}")
    end

    run_migration(tail)
  end
end
