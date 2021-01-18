defmodule XandraMigrator.XandraModels.SchemaMigration do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Xandra.Void

  @primary_key false
  embedded_schema do
    field(:version, :integer)
    field(:inserted_at, :integer)
  end

  def one!(params \\ []) do
    condition = prepare_query_condition(params)

    query = "SELECT * FROM schema_migrations " <> condition <> "ALLOW FILTERING"

    {:ok, page} = Xandra.execute(:xandra, query, [], timestamp_format: :integer)

    case Enum.to_list(page) do
      [] ->
        {:ok, nil}

      [obj] ->
        {:ok, to_struct(obj)}

      unexpected ->
        raise "Unexpected result #{inspect(unexpected)} for query: #{query}. Expected only one row."
    end
  end

  def all!(params \\ []) do
    condition = prepare_query_condition(params)

    query = "SELECT * FROM schema_migrations " <> condition <> " ALLOW FILTERING"

    {:ok, page} = Xandra.execute(:xandra, query, [], timestamp_format: :integer)

    result = page |> Enum.to_list() |> Enum.map(fn el -> to_struct(el) end)

    {:ok, result}
  end

  def new(params) do
    case prepare_insert_query(params) do
      {:ok, query, query_args} ->
        {:ok, %Void{}} = Xandra.execute(:xandra, query, query_args)

        one!(version: query_args["version"])

      {:error, _} = error ->
        error
    end
  end

  defp prepare_insert_query(params) when is_map(params) do
    changeset = changeset(params)

    case changeset.valid? do
      true ->
        schema_migration = apply_changes(changeset)

        query =
          "INSERT INTO schema_migrations (version, inserted_at) " <>
            "VALUES (:version, :inserted_at)"

        {:ok, prepared_query} = Xandra.prepare(:xandra, query)

        query_args =
          schema_migration
          |> Map.from_struct()
          |> Enum.reduce(%{}, fn {key, val}, acc -> Map.put(acc, "#{key}", val) end)

        {:ok, prepared_query, query_args}

      false ->
        {:error, changeset.errors}
    end
  end

  defp changeset(params) do
    changeset(%__MODULE__{}, params)
  end

  defp changeset(obj, params) do
    obj
    |> cast(params, [:version, :inserted_at])
    |> validate_required([:version, :inserted_at])
  end

  defp to_struct(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:version, :inserted_at])
    |> apply_changes
  end

  defp prepare_query_condition(params) do
    prepare_query_condition(params, [])
  end

  defp prepare_query_condition([], []), do: ""

  defp prepare_query_condition([], condition),
    do: "WHERE " <> (condition |> Enum.reverse() |> Enum.join("AND "))

  defp prepare_query_condition([{:version, version} | other_params], condition) do
    prepare_query_condition(other_params, ["version = #{version} " | condition])
  end

  defp prepare_query_condition([bad_param | _other_params], _condition) do
    raise "Unexpected search param #{inspect(bad_param)}."
  end
end
