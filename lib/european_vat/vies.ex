defmodule EuropeanVat.Vies do
  use GenServer

  alias EuropeanVat.Vies.SoapClient

  #
  # Client
  #

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def check_vat(country_code, vat_number) do
    GenServer.call(__MODULE__, {:check_vat, country_code, vat_number})
  end

  #
  # Server
  #

  @wsdl_url "http://ec.europa.eu/taxation_customs/vies/checkVatService.wsdl"

  def init(args \\ []) do
    Keyword.get(args, :wsdl_url, @wsdl_url)
    |> SoapClient.wsdl
  end

  def handle_call({:check_vat, country_code, vat_number}, _from, service) do
    {:reply, SoapClient.check_vat(service, country_code, vat_number), service}
  end

end
