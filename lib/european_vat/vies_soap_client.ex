defmodule EuropeanVat.ViesSoapClient do
  @moduledoc false

  defmodule Service do
    @moduledoc false
    defstruct url: nil
  end

  @wsdl_url "http://ec.europa.eu/taxation_customs/vies/checkVatService.wsdl"

  def wsdl(wsdl_url \\ nil) do
    case HTTPoison.get(wsdl_url || @wsdl_url) do
      {:ok, response} ->
        parse_wsdl(response.body)
      http_error ->
        {:error, http_error}
    end
  end

  # <wsdl:definitions>
  #    ...
  #    <wsdl:service name="checkVatService">
  #     <wsdl:port name="checkVatPort" binding="impl:checkVatBinding">
  #       <wsdlsoap:address location="http://ec.europa.eu/taxation_customs/vies/services/checkVatService"/>
  #     </wsdl:port>
  #   </wsdl:service>
  # </wsdl:definitions>

  @xpath_wsdl_service_location SweetXml.sigil_x("//wsdl:definitions/wsdl:service[name=checkVatService]/wsdl:port[name=checkVatPort]/wsdlsoap:address/@location")

  defp parse_wsdl(xml) do
    case SweetXml.xpath(xml, @xpath_wsdl_service_location) do
      nil ->
        {:error, xml}
      url ->
        {:ok, %Service{url: url}}
    end
  end

  def check_vat(service, country_code, vat_number) do
    case HTTPoison.post(service.url, check_vat_request(country_code, vat_number)) do
      {:ok, response} ->
        parse_check_vat_response(response.body)
      http_error ->
        {:error, http_error}
    end
  end

  defp check_vat_request(country_code, vat_number) do
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="urn:ec.europa.eu:taxud:vies:services:checkVat:types">
      <soap:Body>
        <ns1:checkVat>
          <ns1:countryCode>#{country_code}</ns1:countryCode>
          <ns1:vatNumber>#{vat_number}</ns1:vatNumber>
        </ns1:checkVat>
      </soap:Body>
    </soap:Envelope>
    """
  end

  # <soap:Envelope
  #     xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  #     <soap:Body>
  #         <checkVatResponse
  #             xmlns="urn:ec.europa.eu:taxud:vies:services:checkVat:types">
  #             <countryCode>BE</countryCode>
  #             <vatNumber>0829071668</vatNumber>
  #             <requestDate>2016-01-16+01:00</requestDate>
  #             <valid>true</valid>
  #             <name>SPRL BIGUP</name>
  #             <address>RUE LONGUE 93
  # 1320 BEAUVECHAIN</address>
  #         </checkVatResponse>
  #     </soap:Body>
  # </soap:Envelope>

  @xpath_fault_response SweetXml.sigil_x("//soap:Envelope/soap:Body/soap:Fault/faultstring/text()")
  @xpath_check_vat_response SweetXml.sigil_x("//soap:Envelope/soap:Body/checkVatResponse")
  @attrs_check_vat_response [
    country_code: SweetXml.sigil_x("./countryCode/text()"),
    vat_number:   SweetXml.sigil_x("./vatNumber/text()"),
    request_date: SweetXml.sigil_x("./requestDate/text()"),
    valid:        SweetXml.sigil_x("./valid/text()"),
    name:         SweetXml.sigil_x("./name/text()"),
    address:      SweetXml.sigil_x("./address/text()"),
  ]

  def parse_check_vat_response(xml) do
    case SweetXml.xpath(xml, @xpath_fault_response) do
      nil ->
        xml
        |> SweetXml.xpath(@xpath_check_vat_response, @attrs_check_vat_response)
        |> convert_types(xml)
      fault ->
        {:error, %{valid: false, fault: to_string(fault)}}
    end
  end

  defp convert_types(nil, xml), do: {:error, xml}
  defp convert_types(response, _) do
    {:ok, %{
      response |
      country_code: to_string(response.country_code),
      vat_number: to_string(response.vat_number),
      valid: response.valid == 'true',
      request_date: parse_date(response.request_date),
      name: dashes_to_nil(response.name),
      address: dashes_to_nil(response.address)
    }}
  end

  @request_date_format ~r/\A(\d{4})-(\d{2})-(\d{2})([+-]\d{2}):(\d{2})\z/

  defp parse_date(charlist) do
    case Regex.run(@request_date_format, to_string(charlist)) do
      [_, y, m, d, hh, mm] ->
        {{to_int(y), to_int(m), to_int(d)}, to_int(hh)*60+to_int(mm)}
      _ ->
        {:parse_error, charlist}
    end
  end

  defp to_int(string), do: Integer.parse(string) |> elem(0)

  def dashes_to_nil('---'),    do: nil
  def dashes_to_nil(charlist), do: to_string(charlist)

end
