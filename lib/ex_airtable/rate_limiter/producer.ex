defmodule ExAirtable.RateLimiter.Producer do
  @moduledoc """
  This module defines a struct for managing RateLimiter state. A Ratelimiter contains a map of `%Producer{}`s.
  """

  defstruct interval: :timer.seconds(1),
            max_demand: 5

  @typedoc """
  Track demand from a single BaseQueue GenStage producer
  """
  @type t :: %__MODULE__{
          interval: integer(),
          max_demand: integer()
        }
end
