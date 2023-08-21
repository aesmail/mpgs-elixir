# Mpgs

This package deals with the MasterCard Payment Gateway Service (MPGS).

Check the MPGS API documentation for more details:

https://ap-gateway.mastercard.com/api/documentation/apiDocumentation/rest-json/version/latest/api.html?locale=en_US

## Installation

```elixir
def deps do
  [
    {:mpgs, "~> 1.0"}
  ]
end
```

Documentation can be found at <https://hexdocs.pm/mpgs>.


## Examples

```elixir
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

{:ok, session, html} = Mpgs.authenticate_payment(params)
# Send and render the html on client's browser.
# After a successful or a failed authentication attempt by the user,
# call the capture_payment/1 function.

# include the returned session from the authenticate_payment/1 function in the capture_payment/1 params.
params = Map.put(params, :session, session)

{:ok, response} = Mpgs.capture_payment(params)

response["result"] #=> "SUCCESS"

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
```
