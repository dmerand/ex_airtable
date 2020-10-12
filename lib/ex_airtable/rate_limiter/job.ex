defmodule ExAirtable.RateLimiter.MFA do
  @moduledoc """
  This module defines a struct that is handy for passing data back and forth between functions, as data.

  "MFA" = Module, Function, Arguments
  """

  defstruct module: nil, 
            function: nil,
            args: []

  @typedoc """
  A single job to be run - aka a "MFA" or module, function, argument triplet.
  """
  @type t :: %__MODULE__{
    module: module(),
    function: function(),
    args: [term()]
  }
end
