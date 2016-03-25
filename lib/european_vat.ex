  defmodule EuropeanVat do

  alias EuropeanVat.{Supervisor,Server}

  @typedoc "Alphanumerical string with the country code and number"
  @type vat_number :: String.t

  @typedoc "ISO-3166-2 (2 Letter Country Code)"
  @type country_code :: String.t

  @typedoc "VAT rate type"
  # "standard_rate" | "reduced_rate" | "reduced_rate_alt" | "super_reduced_rate" | "parking_rate"
  @type rate_type :: String.t

  # ISO-3166-2 (2 Letter Country Code)
  @member_states %{
    "AT" => "Austria",
    "BE" => "Belgium",
    "BG" => "Bulgaria",
    "CY" => "Cyprus",
    "CZ" => "Czech Republic",
    "DE" => "Germany",
    "DK" => "Denmark",
    "EE" => "Estonia",
    "ES" => "Spain",
    "FI" => "Finland",
    "FR" => "France",
    "GB" => "United Kingdom",
    "GR" => "Greece",
    "HR" => "Croatia",
    "HU" => "Hungary",
    "IE" => "Ireland",
    "IT" => "Italy",
    "LT" => "Lithuania",
    "LU" => "Luxembourg",
    "LV" => "Latvia",
    "MT" => "Malta",
    "NL" => "Netherlands",
    "PL" => "Poland",
    "PT" => "Portugal",
    "RO" => "Romania",
    "SE" => "Sweden",
    "SI" => "Slovenia",
    "SK" => "Slovakia"
  }

  # Per http://ec.europa.eu/taxation_customs/vies/checkVatService.wsdl
  @vat_number_regex ~r/\A[0-9A-Za-z\+\*\.]{2,12}\z/

  @doc "Starts the application which itself starts the server used communicate with the VAT Information Exchange System.
  The application must be started if you wand to use `check_vat/2`, `check_vat?/2`, `rates/0`, `rates/1` or `rates/2`"
  def start(_type, args) do
    Supervisor.start_link(args)
  end

  @doc """
    Removes unwanted characters from a supposed VAT number

    iex> EuropeanVat.sanitize_vat_number(" BE 0829.071.668  ")
    "BE0829071668"
    iex> EuropeanVat.sanitize_vat_number("be0829071668")
    "BE0829071668"
  """
  @spec sanitize_vat_number(vat_number) :: vat_number
  def sanitize_vat_number(nil), do: ""
  def sanitize_vat_number(vat_number) do
    vat_number
    |> String.replace(~r/[\s\t\.]/, "")
    |> String.upcase
  end

  @doc """

    Determines whether VAT is applicable for a given transaction based on:

      - the seller and buyer country code
      - the presence or not of a VAT number

    This function does *not* verify the validity of the VAT number, only its presence.
    You may use the `check_vat/2` function to ensure a given European VAT number is valid.

    ### Examples:

    Buyer and seller in the same country

    iex> EuropeanVat.must_charge_vat?("BE", "BE", "BE0829071668")
    true

    Buyer and seller in different EU countries, VAT number present

    iex> EuropeanVat.must_charge_vat?("NL", "BE", "BE0829071668")
    true

    Buyer and seller in different EU countries, no VAT number

    iex> EuropeanVat.must_charge_vat?("NL", "BE", nil)
    false
    iex> EuropeanVat.must_charge_vat?("NL", "BE", "")
    false

    Seller in EU, buyer outside of EU, no VAT number

    iex> EuropeanVat.must_charge_vat?("BE", "US", nil)
    false

    Seller in EU, buyer outside of EU, company number

    iex> EuropeanVat.must_charge_vat?("BE", "US", "0000320193")
    false

  """
  @spec must_charge_vat?(country_code, country_code, vat_number) :: boolean
  def must_charge_vat?(seller_country, buyer_country, vat_number) do
    if seller_country == buyer_country do
      true
    else
      case sanitize_vat_number(vat_number) do
        nil -> false
        ""  -> false
        _   -> Dict.has_key?(@member_states, buyer_country)
      end
    end
  end

  @doc """
  """
  @spec check_vat(country_code, vat_number) :: {:ok, map} | {:error, String.t}
  def check_vat(country_code, vat_number) do
    Server.check_vat(Server, country_code, sanitize_vat_number(vat_number))
  end

  @doc """
  """
  @spec check_vat?(country_code, vat_number) :: boolean
  def check_vat?(country_code, vat_number) do
    {:ok, response} = check_vat(country_code, vat_number)
    response.valid
  end

  @doc """
    Returns a map containing VAT rates information for each European country.

    The first call will hit the remote API, the result is cached for next calls
  """
  @spec rates :: map
  def rates do
    Server.rates(Server)
  end

  @doc """
    Returns a map containing VAT rate information for the given two letter ISO country code.

    The first call will hit the remote API, the result is cached for next calls
  """
  @spec rate(country_code) :: map
  def rate(country_code) do
    Server.rates(Server) |> Dict.get(country_code)
  end

  @doc """
    Returns the value for the given VAT rate of the given country code.

    Rate type is a string and can be: `standard_rate`, `reduced_rate`, `reduced_rate_alt`, `super_reduced_rate`, or `parking_rate`.
    If the rate is not applicable, `false` is returned

  """
  @spec rate(country_code, rate_type) :: float | false
  def rate(country_code, rate_type) do
    country_code |> rate |> Dict.get(rate_type)
  end

end
