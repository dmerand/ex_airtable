defmodule ExAirtable.RateLimiter.JobTest do
  use ExUnit.Case, async: true
  alias ExAirtable.RateLimiter.{Job, Request}

  test "runs jobs" do
    job = %Job{module: String, function: :trim, arguments: ["Hello "]}
    assert "Hello" = Job.run(job)
  end

  test "request without callback" do
    request = %Request{
      job: %Job{module: String, function: :to_atom, arguments: ["no_callback"]}
    }
    assert :no_callback = Request.run(request)
  end

  test "request with callback" do
    request = %Request{
      job: %Job{module: String, function: :to_atom, arguments: ["has_callback"]},
      callback: %Job{module: Kernel, function: :send, arguments: [self()]}
    }
    Request.run(request)
    assert_received :has_callback
  end
end
