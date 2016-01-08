defmodule Aya.Driver.Supervisor do
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    driver = Application.get_env(:aya, :driver, Aya.Driver.Default)
    pool_size = Application.get_env(:aya, :driver_pool_size, 10)
    pool_options = [
      name: {:local, :driver_pool},
      worker_module: driver,
      size: pool_size,
      max_overflow: 10
    ]

    children = [
      :poolboy.child_spec(:driver_pool, pool_options, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
