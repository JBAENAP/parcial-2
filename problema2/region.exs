# Programación III - Parcial 2 - Problema 2
# Struct de una región del mapa.

defmodule Region do
  @moduledoc """
  Una región es un grupo de casillas del mismo símbolo unidas en horizontal o
  vertical. `desde` y `hasta` son las esquinas de la caja envolvente.
  """

  defstruct id: 0, simbolo: nil, celdas: [], area: 0, perimetro: 0, desde: nil, hasta: nil

  @doc "Texto de una coordenada como en el CSV: `{2,0}`."
  def coordenada({fila, columna}), do: "{#{fila},#{columna}}"
end
