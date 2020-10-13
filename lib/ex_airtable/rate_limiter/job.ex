defmodule ExAirtable.RateLimiter.Job do
  @moduledoc """
  This module defines a struct that is handy for passing data back and forth between functions, as data.

  "Job" = Module, Function, Arguments
  """

  defstruct module: nil, 
            function: nil,
            arguments: []

  @typedoc """
  A single job to be run - a module, function, and argument.

  This is not to be confused with the [mfa() type](https://hexdocs.pm/elixir/typespecs.html#built-in-types), which is a "module, function, arity" triplet. In this case we need to pass the actual arguments, and we'll let the system take care of pattern-matching for arity.
  """
  @type t :: %__MODULE__{
    module: module(),
    function: function(),
    arguments: [term()]
  }

  @doc """
  Run a given `%Job{}`.
  """
  def run(%__MODULE__{} = job) do
    apply(job.module, job.function, job.arguments)
  end
end
