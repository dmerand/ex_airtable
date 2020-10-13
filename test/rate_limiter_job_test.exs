defmodule ExAirtable.RateLimiter.JobTest do
  use ExUnit.Case, async: true
  alias ExAirtable.RateLimiter.Job

  test "runs jobs" do
    job = %Job{module: String, function: :trim, arguments: ["Hello "]}
    assert "Hello" = Job.run(job)
  end
end
