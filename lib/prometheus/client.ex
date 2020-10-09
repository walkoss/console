defmodule Prometheus.Client do
  alias Prometheus.{Response, Data, Result}
  @headers [{"content-type", "application/x-www-form-urlencoded"}]

  def host(), do: Application.get_env(:watchman, :prometheus)

  def query(query, start, step, variables) do
    query = variable_subst(query, variables)
    HTTPoison.post(
      Path.join(host(), "/api/v1/query_range"),
      {:form, [
        {"query", query},
        {"end", "now"},
        {"start", start},
        {"step", step}
      ]},
      @headers
    )
    |> case do
      {:ok, %{body: body, status_code: 200}} ->
        Poison.decode(body, as: %Response{data: %Data{result: [%Result{}]}})
      error -> error
    end
    |> IO.inspect()
  end

  def extract_labels(query, label) do
    with {:ok, %Response{data: %Data{result: results}}} <- query(query, "now-1h", "5m", %{}) do
      Enum.map(results, fn %Result{metric: metrics} -> Map.get(metrics, label) end)
      |> Enum.uniq()
    else
      _ -> []
    end
  end

  defp variable_subst(value, variables) do
    Enum.reduce(variables, value, fn {key, value}, str ->
      String.replace(str, "$#{key}", value)
    end)
  end
end