defmodule Mpgs.Request do
  alias Mpgs.Parameter

  @api_url "https://ap-gateway.mastercard.com/api/rest/version"
  @api_version "74"

  def start_request(options, method, path, payload) do
    url = build_url(options, path)
    headers = build_headers(options)
    payload = Jason.encode!(payload)

    case method do
      :get -> Finch.build(method, url, headers)
      m -> Finch.build(m, url, headers, payload)
    end
    |> Finch.request(MpgsFinch)
    |> Mpgs.Response.parse_response()
  end

  defp build_url(options, path) do
    base = Parameter.get_var(options, :api_base, "MPGS_API_BASE", @api_url)
    version = Parameter.get_var(options, :api_version, "MPGS_API_VERSION", @api_version)
    merchant = Parameter.get_var(options, :api_merchant, "MGPS_API_MERCHANT")

    "#{base}/#{version}/merchant/#{merchant}/#{path}" |> IO.inspect(label: "build_url")
  end

  defp build_headers(options) do
    username = Parameter.get_var(options, :api_username, "MPGS_API_USERNAME")
    password = Parameter.get_var(options, :api_password, "MPGS_API_PASSWORD")
    IO.inspect(username, label: "username")
    IO.inspect(password, label: "password")
    encoded_credentials = Base.encode64("#{username}:#{password}")

    [
      {"Authorization", "Basic #{encoded_credentials}"},
      {"Content-Type", "application/json"},
      {"Accept", "application/json"}
    ]
  end
end
