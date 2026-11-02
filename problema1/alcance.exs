# Programación III - Parcial 2 - Problema 1
# Stream infinito de conjuntos de centros alcanzables.

defmodule Alcance do
  @moduledoc """
  El paso 0 es el conjunto con el origen. Cada paso siguiente agrega los
  destinos de todos los tramos que salen de los centros ya alcanzados.

  El stream es infinito (`Stream.iterate` nunca termina), pero solo se toman
  pasos hasta que un estado sea igual al anterior. Eso siempre pasa porque el
  conjunto nunca pierde centros y la red tiene una cantidad finita de ellos:
  en algún momento ya no puede crecer más y se repite.
  """

  @doc "Stream infinito de conjuntos alcanzables a partir de `origen`."
  def stream(origen, grafo) do
    Stream.iterate(MapSet.new([origen]), fn conjunto -> siguiente(conjunto, grafo) end)
  end

  @doc """
  Consume el stream hasta el primer estado repetido consecutivo.
  Devuelve `{estados_distintos, paso_estable}`, donde `estados_distintos` es una
  lista de `{paso, conjunto}` y `paso_estable` es el último paso que cambió.
  """
  def hasta_estabilizar(origen, grafo) do
    stream(origen, grafo)
    |> Stream.with_index()
    |> Enum.reduce_while([], fn {conjunto, paso}, estados ->
      case estados do
        [{_paso_anterior, anterior} | _] when anterior == conjunto ->
          {:halt, {Enum.reverse(estados), paso - 1}}

        _ ->
          {:cont, [{paso, conjunto} | estados]}
      end
    end)
  end

  # Agrega al conjunto los destinos de los tramos que salen de cada centro.
  defp siguiente(conjunto, grafo) do
    Enum.reduce(conjunto, conjunto, fn centro, nuevo ->
      Map.get(grafo, centro, [])
      |> Enum.reduce(nuevo, fn tramo, acc -> MapSet.put(acc, tramo.destino) end)
    end)
  end

  @doc "Texto del conjunto ordenado: `{A, B, C}`."
  def mostrar(conjunto) do
    "{" <> (conjunto |> Enum.sort() |> Enum.join(", ")) <> "}"
  end
end
