defmodule ExAirtable.RateLimiter.BaseQueue do
  @moduledoc """
  A Ratelimiter contains a map of `%ExAirtable.RateLimiter.BaseQueues{}`s.

  Each Airtable base has its own rate limit, which is why we operate at the base level for rate-limiting.
  """

  defstruct in_progress: 0,
            interval: :timer.seconds(1),
            max_demand: 5,
            requests: MapSet.new()

  @typedoc """
  Track demand from a single BaseQueue GenStage producer
  """
  @type t :: %__MODULE__{
          in_progress: integer(),
          interval: integer(),
          max_demand: integer(),
          requests: MapSet.t(Request.t())
        }
end
