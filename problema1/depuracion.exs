# Programación III - Parcial 2 - Problema 1
# Validación previa recursiva: depurar la red antes de armar el grafo.
# Aquí no se usa Enum ni Stream, solo recursión con pattern matching.

defmodule Depuracion do
  @moduledoc """
  Recorre los tramos válidos y descarta:
    * los que salen y llegan al mismo centro (bucles), y
    * las repeticiones de la misma pareja origen → destino (se queda la primera).

  Los tramos en sentido contrario (A → B y B → A) son distintos y se conservan.
  """

  @doc """
  Devuelve `{conservados, descartes}`. Cada descarte es `{tramo, motivo}`.
  Los dos resultados quedan en el mismo orden del archivo.
  """
  def depurar(tramos), do: depurar(tramos, %{}, [], [])

  # Caso base: ya no quedan tramos por revisar.
  defp depurar([], _vistos, conservados, descartes) do
    {invertir(conservados), invertir(descartes)}
  end

  # `vistos` es un mapa {origen, destino} => línea donde apareció primero.
  defp depurar([tramo | resto], vistos, conservados, descartes) do
    pareja = {tramo.origen, tramo.destino}

    cond do
      tramo.origen == tramo.destino ->
        motivo = "el tramo sale y llega al mismo centro (#{tramo.origen})"
        depurar(resto, vistos, conservados, [{tramo, motivo} | descartes])

      Map.has_key?(vistos, pareja) ->
        primera = Map.get(vistos, pareja)
        motivo = "pareja #{tramo.origen} → #{tramo.destino} repetida; se conserva la de la línea #{primera}"
        depurar(resto, vistos, conservados, [{tramo, motivo} | descartes])

      true ->
        vistos = Map.put(vistos, pareja, tramo.linea)
        depurar(resto, vistos, [tramo | conservados], descartes)
    end
  end

  # Invierte una lista sin usar Enum.reverse.
  defp invertir(lista), do: invertir(lista, [])
  defp invertir([], acumulado), do: acumulado
  defp invertir([x | resto], acumulado), do: invertir(resto, [x | acumulado])
end
