# Programación III - Parcial 2 - Problema 1
# Búsqueda recursiva de todos los itinerarios simples.

defmodule Busqueda do
  @moduledoc """
  Recorrido en profundidad: desde el centro actual se prueba cada tramo que
  sale de él, siempre que su destino no esté ya en el camino. Así ningún centro
  se repite y solo se avanza en la dirección del tramo.
  """

  @doc "Arma el grafo: un mapa origen => lista de tramos (en el orden del archivo)."
  def armar_grafo(tramos), do: Enum.group_by(tramos, fn t -> t.origen end)

  @doc "Lista con todos los itinerarios simples de `origen` a `destino`."
  def itinerarios(origen, destino, grafo) do
    buscar(origen, destino, grafo, [origen], [])
  end

  # Caso base: llegamos al destino. `camino` y `usados` vienen al revés.
  defp buscar(destino, destino, _grafo, camino, usados) do
    [Itinerario.nuevo(Enum.reverse(camino), Enum.reverse(usados))]
  end

  # Caso recursivo: probamos cada tramo que sale del centro actual.
  defp buscar(actual, destino, grafo, camino, usados) do
    Map.get(grafo, actual, [])
    |> Enum.flat_map(fn tramo ->
      if tramo.destino in camino do
        []
      else
        buscar(tramo.destino, destino, grafo, [tramo.destino | camino], [tramo | usados])
      end
    end)
  end

  @doc """
  Devuelve los números (empezando en 1) de los itinerarios con el menor valor
  según la función `criterio`. Se conservan todos los empates.
  """
  def mejores(itinerarios, criterio) do
    numerados = Enum.with_index(itinerarios, 1)
    minimo = itinerarios |> Enum.map(criterio) |> Enum.min()

    numerados
    |> Enum.filter(fn {it, _n} -> criterio.(it) == minimo end)
    |> Enum.map(fn {_it, n} -> n end)
  end
end
