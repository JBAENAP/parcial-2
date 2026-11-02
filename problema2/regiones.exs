# Programación III - Parcial 2 - Problema 2
# Búsqueda recursiva de las regiones del mapa.

defmodule Regiones do
  @moduledoc """
  El mapa se guarda como `%{{fila, columna} => simbolo}`.

  * `recorrer/5` pasa por todas las casillas en orden (filas y luego columnas)
    y, cuando encuentra una que no es fondo ni está visitada, empieza una región.
  * `explorar/4` se llama a sí misma con los vecinos de arriba, abajo,
    izquierda y derecha que tengan el mismo símbolo.

  Cada casilla se marca como visitada en cuanto se entra a ella, así que
  nunca se recorre dos veces.
  """

  @doc "Convierte la lista de filas en el mapa de coordenadas."
  def armar_mapa(filas) do
    filas
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {{simbolos, _linea}, f}, mapa ->
      simbolos
      |> Enum.with_index()
      |> Enum.reduce(mapa, fn {simbolo, c}, mapa -> Map.put(mapa, {f, c}, simbolo) end)
    end)
  end

  @doc "Encuentra todas las regiones. Los IDs empiezan en 1."
  def encontrar(mapa, num_filas, num_columnas) do
    casillas = for f <- 0..(num_filas - 1), c <- 0..(num_columnas - 1), do: {f, c}
    recorrer(casillas, mapa, MapSet.new(), 1, [])
  end

  defp recorrer([], _mapa, _visitados, _id, regiones), do: Enum.reverse(regiones)

  defp recorrer([pos | resto], mapa, visitados, id, regiones) do
    simbolo = Map.get(mapa, pos)

    if simbolo == "." or MapSet.member?(visitados, pos) do
      recorrer(resto, mapa, visitados, id, regiones)
    else
      {celdas, visitados} = explorar(pos, simbolo, mapa, visitados)
      region = crear_region(id, simbolo, Enum.sort(celdas), mapa)
      recorrer(resto, mapa, visitados, id + 1, [region | regiones])
    end
  end

  # Devuelve {celdas_de_la_region, visitados_actualizados}.
  defp explorar(pos, simbolo, mapa, visitados) do
    visitados = MapSet.put(visitados, pos)

    Enum.reduce(vecinos(pos), {[pos], visitados}, fn vecino, {celdas, visitados} ->
      if Map.get(mapa, vecino) == simbolo and not MapSet.member?(visitados, vecino) do
        {mas_celdas, visitados} = explorar(vecino, simbolo, mapa, visitados)
        {celdas ++ mas_celdas, visitados}
      else
        {celdas, visitados}
      end
    end)
  end

  defp vecinos({f, c}), do: [{f - 1, c}, {f + 1, c}, {f, c - 1}, {f, c + 1}]

  defp crear_region(id, simbolo, celdas, mapa) do
    filas = Enum.map(celdas, fn {f, _c} -> f end)
    columnas = Enum.map(celdas, fn {_f, c} -> c end)

    %Region{
      id: id,
      simbolo: simbolo,
      celdas: celdas,
      area: length(celdas),
      perimetro: perimetro(celdas, simbolo, mapa),
      desde: {Enum.min(filas), Enum.min(columnas)},
      hasta: {Enum.max(filas), Enum.max(columnas)}
    }
  end

  # Un lado cuenta para el perímetro si el vecino está fuera del mapa
  # (Map.get da nil) o tiene otro símbolo.
  defp perimetro(celdas, simbolo, mapa) do
    Enum.reduce(celdas, 0, fn pos, total ->
      lados = Enum.count(vecinos(pos), fn v -> Map.get(mapa, v) != simbolo end)
      total + lados
    end)
  end

  @doc "Las regiones con el valor máximo según `campo` (incluye empates)."
  def maximas([], _campo), do: []

  def maximas(regiones, campo) do
    maximo = regiones |> Enum.map(fn r -> Map.get(r, campo) end) |> Enum.max()
    Enum.filter(regiones, fn r -> Map.get(r, campo) == maximo end)
  end
end
