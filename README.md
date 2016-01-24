# EuropeanVat

European Union VAT number utilities for Elixir.

This library contains functions to:

* sanitize VAT numbers
* check if VAT must be charged for a given transaction
* check the validity of a VAT number using the [VIES web service](http://ec.europa.eu/taxation_customs/vies/faq.html)

This library was inspired by the [eurovat](https://github.com/phusion/eurovat) gem.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add european_vat to your list of dependencies in `mix.exs`:

        def deps do
          [{:european_vat, "~> 0.0.1"}]
        end

  2. Ensure european_vat is started before your application:

        def application do
          [applications: [:european_vat]]
        end

## Usage

### VAT number sanitization

```Elixir

EuropeanVat.sanitize_vat_number(" BE 0829.071.668  ")
# "BE0829071668"

EuropeanVat.sanitize_vat_number("be0829071668")
# "BE0829071668"

```

### VAT applicability check

```Elixir

# Buyer and seller in the same country
EuropeanVat.must_charge_vat?("BE", "BE", "BE0829071668")
# true

# Buyer and seller in different EU countries, VAT number present
EuropeanVat.must_charge_vat?("NL", "BE", "BE0829071668")
# true

# Buyer and seller in different EU countries, no VAT number
EuropeanVat.must_charge_vat?("NL", "BE", nil)
# false

# Seller in EU, buyer outside of EU, no VAT number
EuropeanVat.must_charge_vat?("BE", "US", nil)
# false

```

### VAT number verification

Before interacting with the VIES web service, you must start the dedicated GenServer:

``Èlixir

EuropeanVat.start_link
# {:ok, #PID<0.154.0>}

```

Going forward, you can use the `check_vat/2` function to verify VAT numbers:

```Elixir

EuropeanVat.check_vat("BE", "0829.071.668")
# {:ok,
#  %{address: "RUE LONGUE 93\n1320 BEAUVECHAIN", country_code: "BE",
#    name: "SPRL BIGUP", request_date: {{2016, 1, 24}, 60}, valid: true,
#    vat_number: "0829071668"}}
```

## TODO

* https://euvatrates.com/rates.json
