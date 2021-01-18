defmodule XandraMigrator.SchemaMigrations do
  @moduledoc false

  alias XandraMigrator.XandraModels.SchemaMigration

  def new(params) do
    SchemaMigration.new(params)
  end

  def max_version!() do
    case SchemaMigration.all!() do
      {:ok, []} ->
        nil

      {:ok, migrations} ->
        migrations
        |> Enum.sort_by(fn migration -> migration.version end, :desc)
        |> List.first()
        |> Map.get(:version)
    end
  end
end
