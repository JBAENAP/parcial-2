# Programación III - Parcial 2 - Problema 1
# Struct de un itinerario encontrado por la búsqueda.

defmodule Itinerario do
  @moduledoc """
  Un itinerario es la secuencia de centros desde el origen hasta el destino,
  los tramos que se usaron y los totales de tiempo y costo.
  """

  defstruct centros: [], tramos: [], minutos: 0, costo: 0

  @doc "Arma el itinerario a partir de los centros y tramos (ya en orden)."
  def nuevo(centros, tramos) do
    minutos = Enum.reduce(tramos, 0, fn t, suma -> suma + t.minutos end)
    costo = Enum.reduce(tramos, 0, fn t, suma -> suma + t.costo end)
    %Itinerario{centros: centros, tramos: tramos, minutos: minutos, costo: costo}
  end

  @doc "Número de tramos del itinerario."
  def num_tramos(itinerario), do: length(itinerario.tramos)

  @doc "Los centros unidos con flechas: `A → B → D`."
  def ruta(itinerario), do: Enum.join(itinerario.centros, " → ")
end
