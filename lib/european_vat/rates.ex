defmodule EuropeanVat.Rates do
   @moduledoc false

  @url "https://euvatrates.com/rates.json"

  def fetch(url \\ @url) do
    case HTTPoison.get(url) do
      {:ok, response} ->
        parse(response.body)
      http_error ->
        {:error, http_error}
    end
  end

  defp parse(json) do
    Poison.decode(json)
  end

end
