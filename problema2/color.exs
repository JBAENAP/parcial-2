# Programación III - Parcial 2 - Problema 2
# Struct de un color de la paleta.

defmodule Color do
  @moduledoc "Un símbolo del mapa con su nombre y su color en formato #RRGGBB."

  defstruct simbolo: nil, nombre: nil, hex: nil

  @doc """
  Arma el mapa simbolo => %Color{} a partir de las líneas de la paleta.
  Se llama solo cuando la validación ya pasó.
  """
  def desde_lineas(lineas) do
    Enum.reduce(lineas, %{}, fn {[simbolo, nombre, hex], _linea}, paleta ->
      Map.put(paleta, simbolo, %Color{simbolo: simbolo, nombre: nombre, hex: hex})
    end)
  end
end
