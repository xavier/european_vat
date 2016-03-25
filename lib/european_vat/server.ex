defmodule EuropeanVat.Server do
  use GenServer

  alias EuropeanVat.{ViesSoapClient, Rates}

  defmodule State do
    defstruct service: nil, rates: nil
  end

  #
  # Client
  #

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: Dict.get(args, :name, __MODULE__))
  end

  def check_vat(server, country_code, vat_number) do
    GenServer.call(server, {:check_vat, country_code, vat_number})
  end

  def rates(server) do
    GenServer.call(server, :rates)
  end

  #
  # Server
  #

  def init(args \\ []) do
    {:ok, service} =
      Dict.get(args, :wsdl_url, nil)
      |> ViesSoapClient.wsdl

    {:ok, %State{service: service}}
  end

  def handle_call({:check_vat, country_code, vat_number}, _from, state) do
    {:reply, ViesSoapClient.check_vat(state.service, country_code, vat_number), state}
  end

  def handle_call(:rates, _from, state = %{rates: nil}) do
    {:ok, rates} = Rates.fetch
    {:reply, Dict.get(rates, "rates"), %{state | rates: rates}}
  end
  def handle_call(:rates, _from, state = %{rates: rates}) do
    {:reply, Dict.get(rates, "rates"), state}
  end

end
