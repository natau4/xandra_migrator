defmodule Mix.Tasks.Xandra.Migrate do
  @moduledoc false

  use Mix.Task

  def run(_) do
    Mix.Task.run("app.start")
    XandraMigrator.run_xandra()

    XandraMigrator.migrate()
  end
end
