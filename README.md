# Mpgs

This package deals with the MasterCard Payment Gateway Service (MPGS).

Check the [online documentation](https://hexdocs.pm/mpgs/).

Check the [MPGS API documentation](https://ap-gateway.mastercard.com/api/documentation/apiDocumentation/rest-json/version/latest/api.html?locale=en_US) for more details:

## Installation

```elixir
def deps do
  [
    {:mpgs, "~> 1.0"}
  ]
end
```

## Examples

```elixir
params = %{
  api_username: "my-mpgs-username",
  api_password: "my-mpgs-password",
  api_merchant: "my-mpgs-merchant",
  amount: "15",
  currency: "KWD",
  # provide either a session containing card details (check the online docs for more details)
  session: "SESSION3920348329483922932039",
  # or the actual card details (number, expiry, security code)
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

{:ok, session, html} = Mpgs.authenticate_payment(params)
# Send and render the html on client's browser.
# After a successful or a failed authentication attempt by the user,
# call the capture_payment/1 function.

# The response from the MPGS gateway is POSTED to the response_url value provided in the params.
# The response is something like this:
%{
  "order.id" => "1234567890",
  "transaction.id" => "auth-0987654321",
  "response.gatewayRecommendation" => "PROCEED",
  "result" => "SUCCESS"
  "delegate" => "THREEDS",
  "encryptedData.ciphertext" => "...",
  "encryptedData.nonce" => "...",
  "encryptedData.tag" => "...",
}
# You can check the values of "response.gatewayRecommendation" and "result" to
# decide whether to continue with the capture_payment/1 function.

# include the returned session from the authenticate_payment/1 function in the capture_payment/1 params.
params = Map.put(params, :session, session)
{:ok, response} = Mpgs.capture_payment(params)
response["result"] #=> "SUCCESS"

# To retrieve information about an existing order:
order_params = %{
  api_username: "my-mpgs-username",
  api_password: "my-mpgs-password",
  api_merchant: "my-mpgs-merchant",
  order: "0123456789",
  trx: "0987654321",
}

{:ok, response} = Mpgs.retrieve_transaction(order_params)
response["order"]["amount"] #=> 15
response["result"] #=> "SUCCESS"

# Refund a transaction
order_params = %{
  api_username: "my-mpgs-username",
  api_password: "my-mpgs-password",
  api_merchant: "my-mpgs-merchant",
  order: "0123456789",
  trx: "0987654321",
  amount: "15",
  currency: "KWD"
}

{:ok, response} = Mpgs.refund_transaction(params)
response["result"] #=> "SUCCESS"
response["order"]["status"] #=> "REFUNDED"

# check MPGS availability: true if the API is reachable and operational, false otherwise.
Mpgs.check_availability()
true
```
