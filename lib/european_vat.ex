defmodule EuropeanVat do

  @typedoc "Alphanumerical string with the country code and number"
  @type vat_number :: String.t

  @typedoc "ISO-3166-2 (2 Letter Country Code)"
  @type country_code :: String.t

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

  @doc "Starts the client for the VAT Information Exchange System, required if you wand to use `check_vat/2` or `check_vat?/2`"
  def start_link(args \\ []) do
    EuropeanVat.Vies.start_link(args)
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
    EuropeanVat.Vies.check_vat(country_code, sanitize_vat_number(vat_number))
  end

  @doc """
  """
  @spec check_vat?(country_code, vat_number) :: boolean
  def check_vat?(country_code, vat_number) do
    {:ok, response} = check_vat(country_code, vat_number)
    response.valid
  end

end
