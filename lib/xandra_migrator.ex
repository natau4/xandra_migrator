defmodule XandraMigrator do
  @moduledoc false

  def run_xandra() do
    cassandra_params() |> Xandra.start_link()
  end

  def parrent_app_name() do
    Mix.Project.config()[:app]
  end

  def cassandra_keyspace() do
    parrent_app_name() |> Application.get_env(:xandra) |> Keyword.get(:keyspace)
  end

  defp cassandra_params() do
    params = Application.fetch_env!(:deep_link_service, :xandra)

    fun = &Xandra.execute(&1, "USE #{params[:keyspace]}")

    [
      name: :xandra,
      pool_size: params[:pool_size],
      nodes: [params[:host]],
      after_connect: fun,
      queue_target: params[:queue_target],
      queue_interval: params[:queue_interval]
    ]
  end
end
