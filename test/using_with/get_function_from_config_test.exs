defmodule UsingWith.GetFunctionFromConfig do
  use ExUnit.Case

  test "Get good function" do
    f = fn x-> x+1 end
    config = [ff_function: f]
    f_retrieved = UsingWith.get_function_from_config(config)
    assert f_retrieved.(1) == f.(1)
    assert f_retrieved.(-5) == f.(-5)
  end

  test "No function but multiplier" do
    multiplier = 3
    config = [ff_multiplier: multiplier]
    f_retrieved = UsingWith.get_function_from_config(config)
    Enum.each(1..10, fn _x ->
      y = :rand.uniform()
      assert_in_delta(f_retrieved.(y),y*multiplier, 0.0001)
    end)
  end

end
