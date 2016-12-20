defmodule EuropeanVat.Supervisor do
  use Supervisor

  @moduledoc false

  def start_link(args \\ []) do
    Supervisor.start_link(__MODULE__, args)
  end

  def init(args) do
    children = [
      worker(EuropeanVat.Server, [args])
    ]
    supervise(children, strategy: :one_for_one)
  end
end
