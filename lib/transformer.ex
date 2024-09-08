defmodule DesafioCli.Transformer do
  def to_model_value(value_data) do
    case value_data.type do
      :number -> value_data.value
      :boolean -> value_data.value
      :string -> "\"#{value_data.value}\""
    end
  end

  # def to_value_data(value) do
  #   case value do
  #     value when is_number(value) -> %{value: value, type: :number}
  #     value when is_boolean(value) -> %{value: value, type: :boolean}
  #     value when is_string(value) -> %{value: value, type: :string}
  #   end
  # end
end
