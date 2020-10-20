defmodule ExAirtable.RateLimiter.JobTest do
  use ExUnit.Case, async: true
  alias ExAirtable.RateLimiter.{Job, Request}

  test "runs jobs" do
    job = %Job{module: String, function: :trim, arguments: ["Hello "]}
    assert "Hello" = Job.run(job)
  end

  test "request without callback" do
    request = Request.create({String, :to_atom, ["no_callback"]})
    assert :no_callback = Request.run(request)
  end

  test "request with callback" do
    request =
      Request.create(
        {String, :to_atom, ["has_callback"]},
        {Kernel, :send, [self()]}
      )

    Request.run(request)
    assert_receive :has_callback
  end
end
