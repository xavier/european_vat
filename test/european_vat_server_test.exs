defmodule EuropeanVatServerTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney,  options: [clear_mock: true]

  alias EuropeanVat.Server

  setup_all do
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes")
    :ok
  end

  setup context do
    {:ok, pid} = Server.start_link(name: context.test)
    {:ok, %{server: pid}}
  end

  test "rates", %{server: server} do
    use_cassette "rates" do
      rates = Server.rates(server)
      {:ok, be_rates} = Dict.fetch(rates, "BE")
      assert Dict.get(be_rates, "country") == "Belgium"
      assert Dict.get(be_rates, "standard_rate") == 21.0
    end
  end

  test "check_vat valid", %{server: server} do
    use_cassette "vies_valid" do
      response = Server.check_vat(server, "BE", "0829071668")
      assert {:ok, payload} = response
      assert Dict.get(payload, :valid) == true
    end
  end

  test "check_vat invalid number", %{server: server} do
    use_cassette "vies_invalid_number" do
      response = Server.check_vat(server, "BE", "1234567890")
      assert {:ok, payload} = response
      assert Dict.get(payload, :valid) == false
    end
  end

  test "check_vat invalid country", %{server: server} do
    use_cassette "vies_invalid_country" do
      expected = {:error, %{
        valid: false,
        fault: "INVALID_INPUT"
      }}
      assert expected == Server.check_vat(server, "US", "0829071668")
    end
  end
end

