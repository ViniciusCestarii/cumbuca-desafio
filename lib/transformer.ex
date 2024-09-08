defmodule DesafioCli.Transformer do
  def to_model_value(value_data) do
    case value_data.type do
      :number -> value_data.value
      :boolean -> value_data.value
      :string -> "\"#{value_data.value}\""
    end
  end
end
