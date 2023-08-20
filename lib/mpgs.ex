defmodule Mpgs do
  @moduledoc """
  Documentation for `Mpgs`.
  """
  @api_url "https://ap-gateway.mastercard.com/api/rest/version"
  @api_version "67"

  def create_session(options \\ %{}, payload \\ nil) do
    url = build_url(options, "session")
    headers = build_headers(options)
    payload = Jason.encode!(payload || %{"session" => %{"authenticationLimit" => 25}})

    Finch.build(:post, url, headers, payload)
    |> Finch.request(MpgsFinch)
    |> parse_response()
  end

  def pay_with_3ds2(params) do
    session = get_local_var(params, :session)
    currency = get_local_var(params, :currency, "KWD") |> String.upcase()
    amount = get_local_var(params, :amount)
    headers = build_headers(params)
    url = build_url(params, "session/#{session}")

    payload =
      %{
        "order" => %{
          "amount" => amount,
          "currency" => currency
        }
      }
      |> Jason.encode!()

    {:ok, _response} =
      Finch.build(:put, url, headers, payload)
      |> Finch.request(MpgsFinch)

    order = get_local_var(params, :order)
    trx = get_local_var(params, :trx)
    url = build_url(params, "order/#{order}/transaction/#{trx}") |> IO.inspect(label: "Order URL")

    payload =
      %{
        "apiOperation" => "INITIATE_AUTHENTICATION",
        "session" => %{"id" => session},
        "order" => %{
          "currency" => currency
        },
        "authentication" => %{
          "acceptVersions" => "3DS1,3DS2",
          "purpose" => "PAYMENT_TRANSACTION",
          "channel" => "PAYER_BROWSER"
        }
      }
      |> Jason.encode!()

    {:ok, response} =
      Finch.build(:put, url, headers, payload)
      |> Finch.request(MpgsFinch)
  end

  defp build_url(options, path) do
    base = get_local_var(options, :api_base) || get_env_var("MPGS_API_BASE", @api_url)

    version =
      get_local_var(options, :api_version) || get_env_var("MPGS_API_VERSION", @api_version)

    merchant = get_local_var(options, :api_merchant) || get_env_var("MPGS_API_MERCHANT")

    "#{base}/#{version}/merchant/#{merchant}/#{path}"
  end

  defp build_headers(options) do
    username = get_local_var(options, :api_username) || get_env_var("MPGS_API_USERNAME")
    password = get_local_var(options, :api_password) || get_env_var("MPGS_API_PASSWORD")
    encoded_credentials = Base.encode64("#{username}:#{password}")

    [
      {"Authorization", "Basic #{encoded_credentials}"},
      {"Content-Type", "application/json"},
      {"Accept", "application/json"}
    ]
  end

  defp get_local_var(options, name, default \\ nil), do: Map.get(options, name, default)
  defp get_env_var(name, default \\ nil), do: System.get_env(name, default)

  defp parse_response({:ok, %Finch.Response{status: 201, body: body}}),
    do: {:ok, Jason.decode!(body)}

  defp parse_response({:ok, %Finch.Response{status: 401, body: body}}),
    do: {:error, Jason.decode!(body)}

  defp parse_response(response), do: IO.inspect(response, label: "Error")
end
