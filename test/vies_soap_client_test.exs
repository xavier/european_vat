

defmodule ViesSoapClientTest do
  use ExUnit.Case, async: true

  alias EuropeanVat.Vies.SoapClient
#       <?xml version="1.0" encoding="UTF-8"?>

  test "parse_check_vat_response for valid number" do
    xml = """
      <soap:Envelope
          xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
          <soap:Body>
              <checkVatResponse
                  xmlns="urn:ec.europa.eu:taxud:vies:services:checkVat:types">
                  <countryCode>BE</countryCode>
                  <vatNumber>0829071668</vatNumber>
                  <requestDate>2016-01-16+01:00</requestDate>
                  <valid>true</valid>
                  <name>SPRL BIGUP</name>
                  <address>RUE LONGUE 93
1320 BEAUVECHAIN</address>
              </checkVatResponse>
          </soap:Body>
      </soap:Envelope>
    """

    expected = %{
      country_code: "BE",
      vat_number: "0829071668",
      request_date: {{2016, 1, 16}, 60},
      valid: true,
      name: "SPRL BIGUP",
      address: "RUE LONGUE 93\n1320 BEAUVECHAIN"
    }

    assert SoapClient.parse_check_vat_response(xml) == {:ok, expected}
  end

  test "parse_check_vat_response for invalid number" do
    xml = """
      <soap:Envelope
          xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
          <soap:Body>
              <checkVatResponse
                  xmlns="urn:ec.europa.eu:taxud:vies:services:checkVat:types">
                  <countryCode>BE</countryCode>
                  <vatNumber>BE0829071668</vatNumber>
                  <requestDate>2016-01-16-02:00</requestDate>
                  <valid>false</valid>
                  <name>---</name>
                  <address>---</address>
              </checkVatResponse>
          </soap:Body>
      </soap:Envelope>
    """

    expected = %{
      country_code: "BE",
      vat_number: "BE0829071668",
      request_date: {{2016, 1, 16}, -120},
      valid: false,
      name: nil,
      address: nil,
    }

    assert SoapClient.parse_check_vat_response(xml) == {:ok, expected}
  end

end
