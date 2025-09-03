# https://github.com/ash-project/ash/blob/main/documentation/topics/advanced/writing-extensions.md

defmodule MyApp.Extensions.BaseOld do
  use Spark.Dsl.Extension, transformers: [MyApp.Extensions.Base.AddTimestamps]
end

defmodule MyApp.Extensions.Base.AddTimestamps do
  use Spark.Dsl.Transformer
  # alias Spark.Dsl.Transformer

  def transform2(dsl_state) do
    dsl_state
    # Ash.Resource.Builder has utilities for extending resources
    |> Ash.Resource.Builder.add_new_create_timestamp(:inserted_at2)
    |> Ash.Resource.Builder.add_new_update_timestamp(:updated_at2)
  end

  def transform(dsl_state) do
    # Introspection functions can take a `dsl_state` *or* a module
    if MyApp.Extensions.Base.Info.base_timestamps?(dsl_state) do
      dsl_state
      |> Ash.Resource.Builder.add_new_create_timestamp(:inserted_at3)
      |> Ash.Resource.Builder.add_new_update_timestamp(:updated_at3)
    else
      {:ok, dsl_state}
    end
  end
end

defmodule MyApp.Extensions.Base do
  @base %Spark.Dsl.Section{
    name: :base,
    describe: """
    Configure the behavior of our base extension.
    """,
    examples: [
      """
      base do
        timestamps? false
      end
      """
    ],
    schema: [
      timestamps?: [
        type: :boolean,
        doc: "Set to false to skip adding timestamps",
        default: true
      ]
    ]
  }

  use Spark.Dsl.Extension,
    transformers: [MyApp.Extensions.Base.AddTimestamps],
    sections: [@base]
end

defmodule MyApp.Extensions.Base.Info do
  use Spark.InfoGenerator, extension: MyApp.Extensions.Base, sections: [:base]

  # This will define `base_timestamps?/1`.
end

defmodule MyApp.Tweet do
  use Ash.Resource,
    domain: Tunez.Music,
    extensions: [MyApp.Extensions.Base]

  base do
    # And you can configure it like so
    timestamps?(true)
  end

  # resource do
  #   require_primary_key? false
  # end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  attributes do
    uuid_primary_key :id
  end
end

# Test

# iex(1)> tweet = Tunez.Music.create_tweet
# {:ok,
#  %MyApp.Tweet{
#    id: "97730505-5849-40ba-9334-ac76ef97e464",
#    inserted_at3: ~U[2025-09-02 07:10:45.041667Z],
#    updated_at3: ~U[2025-09-02 07:10:45.041667Z],
#    __meta__: #Ecto.Schema.Metadata<:built, "">
#  }}
