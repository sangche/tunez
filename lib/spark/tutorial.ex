# https://hexdocs.pm/spark/get-started-with-spark.html

defmodule MyLibrary.Validator.Dsl do
  defmodule Field do
    defstruct [:name, :type, :transform, :check]
  end

  @field %Spark.Dsl.Entity{
    name: :field,
    args: [:name, :type],
    target: Field,
    describe: "A field that is accepted by the validator",
    # you can include nested entities here, but
    # note that you provide a keyword list like below
    # we need to know which struct key to place the nested entities in
    # entities: [
    #   key: [...]
    # ],
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "The name of the field"
      ],
      type: [
        type: {:one_of, [:integer, :string]},
        required: true,
        doc: "The type of the field"
      ],
      check: [
        type: {:fun, 1},
        doc: "A function that can be used to check if the value is valid after type validation."
      ],
      transform: [
        type: {:fun, 1},
        doc: "A function that will be used to transform the value after successful validation"
      ]
    ]
  }

  @fields %Spark.Dsl.Section{
    name: :fields,
    schema: [
      required: [
        type: {:list, :atom},
        doc: "The fields that must be provided for validation to succeed"
      ]
    ],
    entities: [
      @field
    ],
    describe: "Configure the fields that are supported and required"
  }

  # use Spark.Dsl.Extension, sections: [@fields]

  use Spark.Dsl.Extension,
    sections: [@fields],
    transformers: [
      MyLibrary.Validator.Transformers.AddId
    ]

  # ,
  # verifiers: [
  #   MyLibrary.Validator.Verifiers.VerifyRequired
  # ]
end

defmodule MyLibrary.Validator do
  use Spark.Dsl,
    default_extensions: [
      extensions: [MyLibrary.Validator.Dsl]
    ]
end

defmodule MyLibrary.Validator.Transformers.AddId do
  use Spark.Dsl.Transformer

  # dsl_state here is a map of the underlying DSL data
  def transform(dsl_state) do
    {:ok,
     Spark.Dsl.Transformer.add_entity(dsl_state, [:fields], %MyLibrary.Validator.Dsl.Field{
       name: :id,
       type: :string
     })}
  end
end

defmodule MyApp.PersonValidator do
  use MyLibrary.Validator

  fields do
    required([:name])
    field :name, :string

    field :email, :string do
      check &String.contains?(&1, "@")
      transform &String.trim/1
    end

    # This syntax is also supported
    # field :email, :string, check: &String.contains?(&1, "@"), transform: &String.trim/1
  end
end

# iex(1)> Spark.Dsl.Extension.get_entities(MyApp.PersonValidator, :fields)
# [
#   %MyLibrary.Validator.Dsl.Field{
#     name: :name,
#     type: :string,
#     transform: nil,
#     check: nil
#   },
#   %MyLibrary.Validator.Dsl.Field{
#     name: :email,
#     type: :string,
#     transform: &String.trim/1,
#     check: &MyApp.PersonValidator.check_0_generated_18E6D5D8C34DFA0EDA8E926DAAEE7E52/1
#   }
# ]

# Final Goal(Not impl yet)

# MyApp.PersonValidator.validate(%{name: "Zach", email: " foo@example.com "})
# {:ok, %{name: "Zach", email: "foo@example.com"}}

# MyApp.PersonValidator.validate(%{name: "Zach", email: " blank "})
# :error

defmodule MyLibrary.Validator.Info do
  use Spark.InfoGenerator, extension: MyLibrary.Validator.Dsl, sections: [:fields]
end

# use
# MyLibrary.Validator.Info.fields(MyApp.PersonValidator)
# outputs the same as above

# iex(8)> MyLibrary.Validator.Info.fields_required(MyApp.PersonValidator)
# {:ok, [:name]}
# iex(9)> MyLibrary.Validator.Info.fields_required!(MyApp.PersonValidator)
# [:name]

defmodule MyLibrary.Validator.Verifiers.VerifyRequired do
  use Spark.Dsl.Verifier

  # dsl_state here is a map of the underlying DSL data
  def verify(dsl_state) do
    # we can use our info module here, even though we are passing in a
    # map of data and not a module! Very handy.

    required = MyLibrary.Validator.Info.fields_required!(dsl_state)
    fields = Enum.map(MyLibrary.Validator.Info.fields(dsl_state), & &1.name)

    if Enum.all?(required, &Enum.member?(fields, &1)) do
      :ok
    else
      {:error,
       Spark.Error.DslError.exception(
         message: "All required fields must be specified in fields",
         path: [:fields, :required],
         # this is how you get the original module out.
         # only do this for display purposes.
         # the module is not yet compiled (we're compiling it right now!), so if you
         # try to call functions on it, you will deadlock the compiler
         # and get an error
         module: Spark.Dsl.Verifier.get_persisted(dsl_state, :module)
       )}
    end
  end
end

# would get compile error if verifiers in extension
defmodule MyApp.BadValidator do
  use MyLibrary.Validator

  fields do
    required([:name, :email])
    field :name, :string
  end
end

# --------------------------------------------------+
# https://hexdocs.pm/spark/Spark.Dsl.Extension.html |
# --------------------------------------------------+

defmodule MyApp.Vehicle do
  use Spark.Dsl
end

defmodule MyApp.Car do
  defstruct [:make, :model, :type]
end

defmodule MyApp.CarExtension do
  @car_schema [
    make: [
      type: :atom,
      required: true,
      doc: "The make of the car"
    ],
    model: [
      type: :atom,
      required: true,
      doc: "The model of the car"
    ],
    type: [
      type: :atom,
      required: true,
      doc: "The type of the car",
      default: :sedan
    ]
  ]

  @car %Spark.Dsl.Entity{
    name: :car,
    describe: "Adds a car",
    examples: [
      "car :ford, :focus"
    ],
    target: MyApp.Car,
    args: [:make, :model],
    schema: @car_schema
  }

  @cars %Spark.Dsl.Section{
    # The DSL constructor will be `cars`
    name: :cars_list,
    describe: """
    Configure what cars are available.

    More, deeper explanation. Always have a short one liner explanation,
    an empty line, and then a longer explanation.
    """,
    entities: [
      # See `Spark.Dsl.Entity` docs
      @car
    ],
    schema: [
      default_manufacturer: [
        type: :atom,
        doc: "The default manufacturer"
      ]
    ]
  }

  use Spark.Dsl.Extension, sections: [@cars]
end

defmodule MyApp.MyResource do
  use MyApp.Vehicle,
    extensions: [MyApp.CarExtension]

  cars_list do
    car(:ford, :focus, type: :sedan)
    car(:toyota, :corolla, type: :sedan)
  end
end

defmodule MyApp.Cars do
  def cars(resource) do
    Spark.Dsl.Extension.get_entities(resource, [:cars_list])
  end
end

# iex(1)> MyApp.Cars.cars(MyApp.MyResource)
# [
#   %MyApp.Car{make: :ford, model: :focus, type: :sedan},
#   %MyApp.Car{make: :toyota, model: :corolla, type: :sedan}
# ]

# -----------------------------

defmodule MyApp.Ash.LogEvents do
  defstruct enabled: true, events: []
end

# Step 2: Define the target modules
defmodule MyApp.Ash.LogEvents.Event do
  defstruct name: nil, description: nil
end

# Step 1: Create the DSL module: defines a new event entity to go inside a log_events block.
defmodule MyApp.Ash.LogEvents.Dsl do
  @event %Spark.Dsl.Entity{
    name: :event,
    target: MyApp.Ash.LogEvents.Event,
    describe: "Log an event with a given name.",
    args: [:name],
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "The name of the event to log."
      ],
      description: [
        type: :string,
        default: "A custom event.",
        doc: "A description of the event."
      ]
    ]
  }

  @log_events %Spark.Dsl.Section{
    name: :log_events,
    describe: "Defines a list of events to log.",
    entities: [@event],
    schema: [
      enabled: [
        type: :boolean,
        default: true
      ]
    ]
  }

  use Spark.Dsl.Extension, sections: [@log_events]
end

# Step 3: Use the extension in an Ash resource
defmodule MyApp.Accounts.User do
  use Ash.Resource,
    domain: Tunez.Music,
    extensions: [MyApp.Ash.LogEvents.Dsl]

  log_events do
    event(:user_created, description: "A new user was created.")
    event(:user_updated, description: "A user's profile was updated.")
  end

  # ... standard resource configuration
  actions do
    defaults [:read, :update, :destroy]

    create :create do
      change MyApp.Ash.Changes.LogEvents
    end
  end

  attributes do
    uuid_primary_key :id
  end
end

defmodule MyApp.Users do
  def users(resource) do
    Spark.Dsl.Extension.get_entities(resource, [:log_events])
  end
end

# iex(4)> MyApp.Users.users(MyApp.Accounts.User)
# [
#   %MyApp.Ash.LogEvents.Event{
#     name: :user_created,
#     description: "A new user was created."
#   },
#   %MyApp.Ash.LogEvents.Event{
#     name: :user_updated,
#     description: "A user's profile was updated."
#   }
# ]

# Step 4: Implement the runtime logic
# An extension is purely declarative at this point.
# You need to write runtime code that reads the extension's configuration and performs an action.
# For our log_events example,
# this could be an Ash change that reads the configured events and logs them after a successful action

defmodule MyApp.Ash.Changes.LogEvents do
  use Ash.Resource.Change

  def change(changeset, _opts, _context) do
    # Read the extension configuration from the resource.
    case Ash.Resource.Info.fields(changeset.data)
         |> Keyword.get(MyApp.Ash.LogEvents.Dsl) do
      %MyApp.Ash.LogEvents{events: events, enabled: true} ->
        # Log the events. This is just an example.
        for event <- events do
          IO.puts("Logging event: #{inspect(event)}")
        end

        changeset

      x ->
        IO.puts("x: #{inspect(x)} #{inspect(Ash.Resource.Info.attributes(changeset.data))}")
        IO.puts("log_events: #{inspect(MyApp.Users.users(changeset.data))}")
        changeset
    end
  end
end
