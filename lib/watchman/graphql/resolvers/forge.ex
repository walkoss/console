defmodule Watchman.GraphQl.Resolvers.Forge do
  alias Watchman.Forge.Repositories
  alias Watchman.Forge.{Connection, PageInfo}
  alias Watchman.Services.Forge
  alias Watchman.Kube.Client

  def list_installations(args, _) do
    Repositories.list_installations(args[:first], args[:after])
    |> clean_up_connection()
  end

  def list_applications(_, _) do
    with {:ok, %{items: items}} <- Client.list_applications(),
      do: {:ok, items}
  end

  def resolve_application(%{name: name}, _), do: Client.get_application(name)

  def resolve_configuration(%{metadata: %{name: name}}, first, second),
    do: resolve_configuration(%{name: name}, first, second)
  def resolve_configuration(%{name: name}, _, _) do
    Forge.values_file(name)
    |> case do
      {:ok, vals} -> {:ok, vals}
      _ -> {:ok, nil}
    end
  end

  def update_configuration(%{repository: repo, content: content}, _) do
    with {:ok, conf} <- Watchman.Deployer.update(repo, content) do
      {:ok, %{configuration: conf}}
    end
  end

  defp clean_up_connection({:ok, %Connection{pageInfo: page_info, edges: edges}}) do
    {:ok, %{page_info: clean_up_page_info(page_info), edges: edges}}
  end

  defp clean_up_page_info(%PageInfo{endCursor: end_c, hasNextPage: has_next}),
    do: %{end_cursor: end_c, has_next_page: has_next}
end