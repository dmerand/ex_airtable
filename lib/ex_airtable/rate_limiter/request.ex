defmodule ExAirtable.RateLimiter.Request do
  @moduledoc """
  The RateLimiter takes a `%Request{}`, runs its `:job` and sends the results to the `:callback` function as arguments. Any arguments defined in the `:callback` `%MFA{}` will be ignored.
  """

  alias ExAirtable.RateLimiter.MFA

  defstruct job: nil, 
            callback: nil

  @typedoc """
  A request to an `ExAirtable.RateLimiter`.
  """
  @type t :: %__MODULE__{
    job: MFA.t(),
    callback: MFA.t(),
  }
end
