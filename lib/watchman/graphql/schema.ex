defmodule Watchman.GraphQl.Schema do
  use Watchman.GraphQl.Schema.Base
  alias Watchman.Schema
  alias Watchman.GraphQl.Resolvers.{Build, Forge, User}
  import_types Absinthe.Plug.Types
  import_types Watchman.GraphQl.CustomTypes

  ## ENUMS
  ecto_enum :status, Schema.Build.Status
  ecto_enum :build_type, Schema.Build.Type

  enum :webhook_health do
    value :healthy
    value :unhealthy
  end

  enum :webhook_type do
    value :piazza
  end

  ## INPUTS

  input_object :build_attributes do
    field :repository, non_null(:string)
    field :type,       :build_type
    field :message,    :string
  end

  input_object :user_attributes do
    field :name,     :string
    field :email,    :string
    field :password, :string
  end

  input_object :webhook_attributes do
    field :url, non_null(:string)
  end

  input_object :invite_attributes do
    field :email, :string
  end

  input_object :label_input do
    field :name,  :string
    field :value, :string
  end

  ## OBJECTS

  object :user do
    field :id, non_null(:id)
    field :name, non_null(:string)
    field :email, non_null(:string)
    field :deleted_at, :datetime

    field :jwt, :string, resolve: fn
      %{id: id, jwt: jwt}, _, %{context: %{current_user: %{id: id}}} -> {:ok, jwt}
      _, _, %{context: %{current_user: %{}}} -> {:error, "you can only query your own jwt"}
      %{jwt: jwt}, _, _ -> {:ok, jwt}
    end

    field :background_color, :string, resolve: fn
      user, _, _ -> User.background_color(user)
    end

    timestamps()
  end

  object :invite do
    field :secure_id, non_null(:string)
    field :email, :string
  end

  object :build do
    field :id,           non_null(:id)
    field :repository,   non_null(:string)
    field :type,         non_null(:build_type)
    field :status,       non_null(:status)
    field :message,      :string
    field :completed_at, :datetime
    field :sha,          :string

    connection field :commands, node_type: :command do
      resolve &Build.list_commands/2
    end

    field :creator,  :user, resolve: dataloader(User)
    field :approver, :user, resolve: dataloader(User)
    field :changelogs, list_of(:changelog), resolve: dataloader(Build)

    timestamps()
  end

  object :changelog do
    field :id,      non_null(:id)
    field :repo,    non_null(:string)
    field :tool,    non_null(:string)
    field :content, :string

    timestamps()
  end

  object :command do
    field :id,           non_null(:id)
    field :command,      non_null(:string)
    field :exit_code,    :integer
    field :stdout,       :string
    field :completed_at, :datetime
    field :build,        :build, resolve: dataloader(Build)

    timestamps()
  end

  object :webhook do
    field :id,      non_null(:id)
    field :url,     non_null(:string)
    field :health,  non_null(:webhook_health)
    field :type,    non_null(:webhook_type)

    timestamps()
  end

  object :installation do
    field :id, non_null(:id)
    field :repository, :repository
  end

  object :repository do
    field :id,            non_null(:id)
    field :name,          non_null(:string)
    field :description,   :string
    field :icon,          :string
    field :configuration, :string, resolve: &Forge.resolve_configuration/3
    field :grafana_dns,   :string, resolve: fn _, _, _ ->
      {:ok, Watchman.conf(:grafana_dns)}
    end
  end

  object :dashboard do
    field :id,   non_null(:string), resolve: fn %{metadata: %{name: n}}, _, _ -> {:ok, n} end
    field :spec, non_null(:dashboard_spec)
  end

  object :dashboard_spec do
    field :name,        :string
    field :description, :string
    field :timeslices,  list_of(:string)
    field :labels,      list_of(:dashboard_label)
    field :graphs,      list_of(:dashboard_graph)
  end

  object :dashboard_label do
    field :name,   non_null(:string)
    field :values, list_of(:string)
  end

  object :dashboard_graph do
    field :name,    non_null(:string)
    field :queries, list_of(:dashboard_metric)
    field :format,  :string
  end

  object :dashboard_metric do
    field :legend, :string
    field :query,  :string
    field :results, list_of(:metric_result)
  end

  object :metric_result do
    field :timestamp, :integer, resolve: fn %{timestamp: ts}, _, _ -> {:ok, ceil(ts)} end
    field :value,     :string
  end

  object :configuration do
    field :configuration, non_null(:string)
  end

  object :log_stream do
    field :stream, :map
    field :values, list_of(:metric_result)
  end

  object :application do
    field :name,   non_null(:string), resolve: fn %{metadata: %{name: name}}, _, _ -> {:ok, name} end
    field :spec,   non_null(:application_spec)
    field :status, non_null(:application_status)

    field :configuration, :string, resolve: &Forge.resolve_configuration/3
  end

  object :application_spec do
    field :descriptor, non_null(:application_descriptor)
    field :components, list_of(:component)
  end

  object :application_descriptor do
    field :type,        non_null(:string)
    field :version,     non_null(:string)
    field :description, non_null(:string)
    field :icons,       list_of(:string), resolve: fn %{icons: icons}, _, _ ->
      {:ok, Enum.map(icons, & &1.src)}
    end
  end

  object :component do
    field :group, non_null(:string)
    field :kind,  non_null(:string)
  end

  object :application_status do
    field :components,       list_of(:status_component)
    field :conditions,       list_of(:status_condition)
    field :components_ready, non_null(:string)
  end

  object :status_component do
    field :group,  :string
    field :kind,   non_null(:string)
    field :name,   non_null(:string)
    field :status, non_null(:string)
  end

  object :status_condition do
    field :message, non_null(:string)
    field :reason,  non_null(:string)
    field :status,  non_null(:string)
    field :type,    non_null(:string)
  end

  delta :build
  delta :command
  delta :application

  connection node_type: :build
  connection node_type: :command
  connection node_type: :installation
  connection node_type: :webhook
  connection node_type: :user
end