defmodule UsingWith do
  def get_function_from_config(config) do
    with function <- Keyword.get(config, :ff_function) do
      if is_nil(function) do
        multiplier = Keyword.fetch!(config, :ff_multiplier)
        fn x -> x*multiplier end
      else
        function
      end
    end
  end
end
