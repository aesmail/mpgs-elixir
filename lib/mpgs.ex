defmodule Mpgs do
  @moduledoc """
  This module deals with the MasterCard Payment Gateway Service (MPGS).

  Check the MPGS API documentation for more details:

  https://ap-gateway.mastercard.com/api/documentation/apiDocumentation/rest-json/version/latest/api.html?locale=en_US
  """

  @api_url "https://ap-gateway.mastercard.com/api/rest/version"
  @api_version "74"

  @doc """
  Use this function to start the payment process.

  The value of the function is a piece of HTML that should be rendered on the client's browser.

  This funciton takes a map and returns a tuple.

  Available map keys:
  - `api_username`. Required. Optional if there is an env variable called `MPGS_API_USERNAME`.
  - `api_password`. Required. Optional if there is an env variable called `MPGS_API_PASSWORD`.
  - `api_base`. Optional. Defaults to #{@api_url}.
  - `api_version`. Optional. Defaults to #{@api_version}.
  - `api_merchant`. Required.
  - `currency`. Optional. The 3-digit currency code. Defaults to KWD.
  - `amount`. Required. It must be a number that indicates the total amount to be paid.
  - `card_number`. Required. The 16-digit card number used for the payment.
  - `expiry_month`. Required. The card's 2-digit expiry month.
  - `expiry_year`. Required. The card's 2-digit expiry year.
  - `security_code`. Required. The card's 3-digit (or 4-digit) CVV code.
  - `order`. Required. The order number.
  - `trx`. Required. The transaction number.
  - `response_url`. Required. The URL that will receive the authentication response from the MPGS gateway.
  - `browser_agent`. Required. The user's browser agent string.
  - `full_page_redirect`. Optional. If `true`, this function will return a complete html document which can be rendered as a full page.

  Return values:
  - `{:ok, session, html}`. The `html` value should be rendered on the client's web browser. The `session` should be used with the `capture_payment/1` function.
  - `{:error, exception}`. An error occurred while processing the authentication request.

  Example:

  ```
  params = %{
    api_username: "my-mpgs-username",
    api_password: "my-mpgs-password",
    api_merchant: "my-mpgs-merchant",
    amount: "15",
    currency: "KWD",
    card_number: "1234567890123456",
    expiry_month: "10",
    expiry_year: "25",
    security_code: "123",
    order: "0123456789",
    trx: "0987654321",
    response_url: "http://example.com/payment/mpgs/response/",
    browser_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)...Version/16.5.2 Safari/605.1.15",
    full_page_redirect: true,
  }

  {:ok, session, html} = authenticate_payment(params)
  # Send and render the html on client's browser.
  # After a successful or a failed authentication attempt by the user,
  # call the capture_payment/1 function.
  params = Map.put(params, :session, session)
  {:ok, result} = capture_payment(params)
  ```
  """
  @spec authenticate_payment(map()) :: {:ok, String.t(), String.t()}
  def authenticate_payment(params) do
    {:ok, result} = create_session(params)
    session = result["session"]["id"]
    params = Map.put(params, :session, session)
    {:ok, _result} = update_session_data(params)
    {:ok, _result} = initiate_authentication(params)
    {:ok, result} = authenticate_payer(params)

    html =
      if Map.get(params, :full_page_redirect, false) do
        rebuild_html_form(result["authentication"]["redirect"]["html"])
      else
        result["authentication"]["redirect"]["html"]
      end

    {:ok, session, html}
  end

  defp create_session(params) do
    url = build_url(params, "session")
    headers = build_headers(params)
    default_session = %{"session" => %{"authenticationLimit" => 25}}

    payload =
      params
      |> get_local_var(:session_payload, default_session)
      |> Jason.encode!()

    Finch.build(:post, url, headers, payload)
    |> Finch.request(MpgsFinch)
    |> parse_response()
  end

  defp update_session_data(params) do
    session = get_local_var(params, :session)
    currency = get_local_var(params, :currency, "KWD") |> String.upcase()
    amount = get_local_var(params, :amount)
    card_number = get_local_var(params, :card_number)
    expiry_month = get_local_var(params, :expiry_month)
    expiry_year = get_local_var(params, :expiry_year)
    security_code = get_local_var(params, :security_code)

    headers = build_headers(params)
    url = build_url(params, "session/#{session}")

    payload =
      %{
        "order" => %{
          "amount" => amount,
          "currency" => currency
        },
        "sourceOfFunds" => %{
          "type" => "CARD",
          "provided" => %{
            "card" => %{
              "number" => card_number,
              "expiry" => %{
                "month" => expiry_month,
                "year" => expiry_year
              },
              "securityCode" => security_code
            }
          }
        }
      }
      |> Jason.encode!()

    Finch.build(:put, url, headers, payload)
    |> Finch.request(MpgsFinch)
    |> parse_response()
  end

  defp initiate_authentication(params) do
    session = get_local_var(params, :session)
    currency = get_local_var(params, :currency, "KWD") |> String.upcase()
    headers = build_headers(params)
    order = get_local_var(params, :order)
    trx = get_local_var(params, :trx)
    url = build_url(params, "order/#{order}/transaction/auth-#{trx}")

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

    Finch.build(:put, url, headers, payload)
    |> Finch.request(MpgsFinch)
    |> parse_response()
  end

  defp authenticate_payer(params) do
    session = get_local_var(params, :session)
    currency = get_local_var(params, :currency, "KWD") |> String.upcase()
    amount = get_local_var(params, :amount)
    browser_agent = get_local_var(params, :browser_agent)
    headers = build_headers(params)
    order = get_local_var(params, :order)
    trx = get_local_var(params, :trx)
    response_url = get_local_var(params, :response_url)

    payload =
      %{
        "apiOperation" => "AUTHENTICATE_PAYER",
        "session" => %{"id" => session},
        "order" => %{
          "amount" => amount,
          "currency" => currency
        },
        "device" => %{
          "browser" => browser_agent,
          "browserDetails" => %{
            "3DSecureChallengeWindowSize" => "390_X_400",
            "acceptHeaders" => "text/html",
            "colorDepth" => "24",
            "javaEnabled" => "true",
            "javaScriptEnabled" => "true",
            "language" => "en",
            "screenHeight" => "400",
            "screenWidth" => "600",
            "timeZone" => "180"
          }
        },
        "authentication" => %{
          "redirectResponseUrl" => response_url
        }
      }
      |> Jason.encode!()

    url = build_url(params, "order/#{order}/transaction/auth-#{trx}")

    Finch.build(:put, url, headers, payload)
    |> Finch.request(MpgsFinch)
    |> parse_response()
  end

  @doc """
  Use this function to capture (charge) the card.

  This function must be used after the `authenticate_payment/1` function.

  Available map keys:
  - `session`. Required. This is obtained from calling `authenticate_payment/1` first.
  - `currency`. Optional. Defaults to `KWD`.
  - `amount`. Required. The same amount used with the `authenticate_payment/1` function.
  - `order`. Required. The same order number used with the `authenticate_payment/1` function.
  - `trx`. Required. The same transaction number used with the `authenticate_payment/1` function.
  - `api_username`. Required. Optional if there is an env variable called `MPGS_API_USERNAME`.
  - `api_password`. Required. Optional if there is an env variable called `MPGS_API_PASSWORD`.
  - `api_base`. Optional. Defaults to #{@api_url}.
  - `api_version`. Optional. Defaults to #{@api_version}.
  - `api_merchant`. Required.
  """
  def capture_payment(params) do
    session = get_local_var(params, :session)
    currency = get_local_var(params, :currency, "KWD") |> String.upcase()
    amount = get_local_var(params, :amount)
    order = get_local_var(params, :order)
    trx = get_local_var(params, :trx)

    payload =
      %{
        "apiOperation" => "PAY",
        "session" => %{"id" => session},
        "authentication" => %{"transactionId" => "auth-" <> trx},
        "transaction" => %{"reference" => order},
        "order" => %{
          "currency" => currency,
          "amount" => amount,
          "reference" => order
        }
      }
      |> Jason.encode!()

    url = build_url(params, "order/#{order}/transaction/#{trx}")
    headers = build_headers(params)

    Finch.build(:put, url, headers, payload)
    |> Finch.request(MpgsFinch)
    |> parse_response()
  end

  @doc """
  Retrieves details about an existing transaction.

  Available map keys:
  - `order`. Required. The same order number used with the `authenticate_payment/1` function.
  - `trx`. Required. The same transaction number used with the `authenticate_payment/1` function.
  - `api_username`. Required. Optional if there is an env variable called `MPGS_API_USERNAME`.
  - `api_password`. Required. Optional if there is an env variable called `MPGS_API_PASSWORD`.
  - `api_base`. Optional. Defaults to #{@api_url}.
  - `api_version`. Optional. Defaults to #{@api_version}.
  - `api_merchant`. Required.
  """
  def retrieve_transaction(params) do
    order = get_local_var(params, :order)
    trx = get_local_var(params, :trx)
    headers = build_headers(params)
    url = build_url(params, "order/#{order}/transaction/#{trx}")

    Finch.build(:get, url, headers)
    |> Finch.request(MpgsFinch)
    |> parse_response()
  end

  defp rebuild_html_form(html) do
    html
    |> String.replace(~s/target="challengeFrame"/, "")
    |> String.replace("iframe", "div")
    |> String.replace(~s/target="redirectTo3ds1Frame"/, "")
    |> then(fn content -> "<html><body>#{content}</body></html>" end)
  end

  def refund_transaction(params) do
    order = get_local_var(params, :order)
    trx = get_local_var(params, :trx)
    amount = get_local_var(params, :amount)
    currency = get_local_var(params, :currency, "KWD")
    headers = build_headers(params)
    url = build_url(params, "order/#{order}/transaction/ref-#{trx}")

    payload =
      %{
        "apiOperation" => "REFUND",
        "transaction" => %{
          "amount" => amount,
          "currency" => currency
        }
      }
      |> Jason.encode!()

    Finch.build(:put, url, headers, payload)
    |> Finch.request(MpgsFinch)
    |> parse_response()
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

  defp get_local_var(params, name, default \\ nil) do
    name_str = to_string(name)
    Map.get(params, name) || Map.get(params, name_str) || default
  end

  defp get_env_var(name, default \\ nil), do: apply(System, :get_env, [name, default])

  defp parse_response({:ok, %Finch.Response{status: status, body: body}})
       when status in 200..299 do
    {:ok, Jason.decode!(body)}
  end

  defp parse_response({:ok, %Finch.Response{body: body}}), do: {:error, Jason.decode!(body)}

  defp parse_response({:error, exception}), do: {:error, exception}
end
