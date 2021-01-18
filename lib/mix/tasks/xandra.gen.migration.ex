defmodule Mix.Tasks.Xandra.Gen.Migration do
  @moduledoc false

  use Mix.Task

  import Macro, only: [camelize: 1, underscore: 1]
  import Mix.Generator

  @app Mix.Project.config()[:app]

  def run(args) do
    Mix.Task.run("app.start")
    XandraMigrator.run_xandra()

    case OptionParser.parse!(args, strict: []) do
      {_opts, [name]} ->
        create_migration_file(name)

      {_, _} ->
        Mix.raise(
          "Expected xandra.gen.migration to receive the migration file name, " <>
            "got: #{inspect(Enum.join(args, " "))}"
        )
    end
  end

  defp create_migration_file(name) do
    path = migrations_path!()

    base_name = "#{underscore(name)}.exs"
    file = Path.join(path, "#{timestamp()}_#{base_name}")

    if Path.wildcard(file) != [] do
      Mix.raise(
        "Migration can't be created, there is already a migration file with name #{base_name}."
      )
    end

    assigns = [
      mod: Module.concat([@app |> to_string() |> camelize(), Xandra, Migrations, camelize(name)])
    ]

    create_file(file, migration_template(assigns))

    Mix.shell().info("Migration #{file} was created.")
  end

  defp migrations_path!() do
    path = Path.join([File.cwd!(), "priv", "xandra", "migrations"])

    if !File.exists?(path) || !File.dir?(path) do
      Mix.raise("Expected to exist directory #{path} for migrations")
    end

    path
  end

  defp timestamp() do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: <<?0, ?0 + i>>
  defp pad(i), do: to_string(i)

  embed_template(:migration, """
  defmodule <%= inspect @mod %> do

    def up do

    end
  end
  """)
end
