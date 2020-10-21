defmodule ExAirtable.RateLimiter.Request do
  @moduledoc """
  The RateLimiter takes an `%ExAirtable.RateLimiter.Request{}`, runs its `:job` and (optionally) sends the results to the `:callback` function as arguments. 

  Any arguments defined in the `:callback` `%Job{}` will be prepended to the function arguments, with the results of `:job` being the final argument passed.
  """

  alias ExAirtable.RateLimiter.Job

  defstruct job: nil,
            callback: nil,
            created: DateTime.now!("Etc/UTC")

  @typedoc """
  A request to an `ExAirtable.RateLimiter`.
  """
  @type t :: %__MODULE__{
          job: Job.t(),
          callback: Job.t(),
          created: DateTime.t()
        }

  @doc """
  Create a request
  """
  def create({module, function, arguments}) do
    %__MODULE__{
      job: %Job{module: module, function: function, arguments: arguments}
    }
  end

  def create(
        {module, function, arguments},
        {callback_module, callback_function, callback_arguments}
      ) do
    %__MODULE__{
      job: %Job{module: module, function: function, arguments: arguments},
      callback: %Job{
        module: callback_module,
        function: callback_function,
        arguments: callback_arguments
      }
    }
  end

  @doc """
  Run a given request, piping the result to the given callback function (if any).

  If arguments are given in the request.callback, then the result of running the request.job will be the final argument after the arguments specified in the callback.
  """
  def run(%__MODULE__{} = request) do
    result = Job.run(request.job)

    if request.callback do
      arguments = request.callback.arguments ++ [result]
      apply(request.callback.module, request.callback.function, arguments)
    else
      result
    end
  end
end
