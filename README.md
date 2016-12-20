# EuropeanVat

European Union VAT utilities for Elixir.

This library contains functions to:

* sanitize European VAT numbers
* check if VAT must be charged for a given transaction
* check the validity of a VAT number using the [VIES web service](http://ec.europa.eu/taxation_customs/vies/faq.html)
* obtain up-to-date VAT rates for all EU countries

This library was inspired by the [eurovat](https://github.com/phusion/eurovat) gem but includes additional features.

## Installation

_This library is still a work in progress and **has not been published yet** on Hex._

The package can be installed via Hex as:

  1. Add european_vat to your list of dependencies in `mix.exs`:

        def deps do
          [{:european_vat, "~> 0.0.1"}]
        end

  2. Ensure european_vat is started before your application in `mix.exs`:

        def application do
          [applications: [:european_vat]]
        end

## Usage

### VAT Number Sanitization

```Elixir

EuropeanVat.sanitize(" BE 0829.071.668  ")
# "BE0829071668"

EuropeanVat.sanitize("be0829071668")
# "BE0829071668"

```

### VAT Applicability Check

```Elixir

# Buyer and seller in the same country
EuropeanVat.charge?("BE", "BE", "BE0829071668")
# true

# Buyer and seller in different EU countries, VAT number present (business)
EuropeanVat.charge?("NL", "BE", "BE0829071668")
# false

# Buyer and seller in different EU countries, no VAT number (consumer)
EuropeanVat.charge?("NL", "BE", nil)
# true

# Seller in EU, buyer outside of EU, no VAT number
EuropeanVat.charge?("BE", "US", nil)
# false

```

### VAT Number Verification

> Before interacting with the VIES web service, you **must** start the EuropeanVat application (see Installation).

Going forward, you can use the `check/2` function to verify VAT numbers:

```Elixir

EuropeanVat.check("BE", "0829.071.668")
# {:ok,
#  %{address: "RUE LONGUE 93\n1320 BEAUVECHAIN", country_code: "BE",
#    name: "SPRL BIGUP", request_date: {{2016, 1, 24}, 60}, valid: true,
#    vat_number: "0829071668"}}

```

### VAT Rate Lookup

> Before interacting with the VAT rates lookup service, you **must** start the EuropeanVat application (see Installation).


You can lookup up-to-date VAT rate information based on a ISO-3166-2 country code:

```Elixir

EuropeanVat.rate("FI")
# %{"country" => "Finland", "parking_rate" => false, "reduced_rate" => 14.0,
#  "reduced_rate_alt" => 10.0, "standard_rate" => 24.0,
#  "super_reduced_rate" => false}

```

## License

Copyright 2016 Xavier Defrang

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

```
http://www.apache.org/licenses/LICENSE-2.0
```

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
