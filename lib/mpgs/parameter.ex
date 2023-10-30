defmodule Mpgs.Parameter do
  def get_var(params, local_name, env_name, default \\ nil) do
    get_local_var(params, local_name) || get_env_var(env_name, default)
  end

  def get_local_var(params, name, default \\ nil) do
    name_str = to_string(name)
    Map.get(params, name) || Map.get(params, name_str) || default
  end

  def get_env_var(name, default \\ nil), do: apply(System, :get_env, [name, default])
end
