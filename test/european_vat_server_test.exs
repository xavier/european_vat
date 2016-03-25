defmodule EuropeanVatServerTest do
  use ExUnit.Case

  alias EuropeanVat.Server

  setup context do
    {:ok, pid} = Server.start_link(name: context.test)
    {:ok, %{server: pid}}
  end

  test "rates", %{server: server} do
    rates = Server.rates(server)
    {:ok, be_rates} = Dict.fetch(rates, "BE")
    assert Dict.get(be_rates, "country") == "Belgium"
    assert Dict.get(be_rates, "standard_rate") == 21.0
  end

  test "check_vat valid", %{server: server} do
    response = Server.check_vat(server, "BE", "0829071668")
    assert {:ok, payload} = response
    assert Dict.get(payload, :valid) == true
  end

  test "check_vat invalid number", %{server: server} do
    response = Server.check_vat(server, "BE", "1234567890")
    assert {:ok, payload} = response
    assert Dict.get(payload, :valid) == false
  end

  test "check_vat invalid country", %{server: server} do
    expected = {:error, %{
      valid: false,
      fault: "INVALID_INPUT"
    }}
    assert expected == Server.check_vat(server, "US", "0829071668")
  end
end

