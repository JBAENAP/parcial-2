# Programación III - Parcial 2 - Problema 2
# Validación previa recursiva del mapa y la paleta.
# Aquí no se usa Enum ni Stream, solo recursión con pattern matching.

defmodule Validacion do
  @moduledoc """
  Revisa que:
    * el mapa tenga filas, ninguna vacía y todas del mismo largo,
    * cada símbolo del mapa esté en la paleta,
    * la paleta tenga 3 campos por línea, colores #RRGGBB, sin símbolos repetidos,
    * el símbolo `.` esté en la paleta.

  Se juntan todos los errores, no solo el primero.
  """

  @doc """
  `filas` es una lista de `{simbolos, linea}` y `paleta` una lista de
  `{campos, linea}`. Devuelve `{:ok, filas_del_mapa}` o `{:error, errores}`.
  """
  def validar(filas, paleta) do
    {simbolos, errores_paleta} = revisar_paleta(paleta, %{}, [])

    errores_paleta =
      if Map.has_key?(simbolos, ".") do
        errores_paleta
      else
        ["Paleta: falta el símbolo '.' (fondo)" | errores_paleta]
      end

    # Las líneas en blanco al inicio y al final del mapa se ignoran;
    # las que quedan en medio de dos filas cuentan como fila vacía.
    filas = quitar_vacias_al_final(quitar_vacias_al_inicio(filas))

    errores_mapa =
      case filas do
        [] ->
          ["Mapa: el archivo no tiene filas"]

        [{primera, _linea} | _] ->
          errores = revisar_filas(filas, length(primera), 0, [])
          revisar_simbolos(filas, simbolos, 0, errores)
      end

    case invertir(errores_paleta) ++ invertir(errores_mapa) do
      [] -> {:ok, filas}
      errores -> {:error, errores}
    end
  end

  # ---------------------------------------------------------------- paleta

  # Devuelve {mapa simbolo => línea, errores}. El mapa sirve para detectar
  # repetidos y luego para saber qué símbolos están definidos.
  defp revisar_paleta([], simbolos, errores), do: {simbolos, errores}

  defp revisar_paleta([{[simbolo, nombre, hex], linea} | resto], simbolos, errores) do
    errores =
      if simbolo == "" do
        ["Paleta línea #{linea}: el símbolo está vacío" | errores]
      else
        errores
      end

    errores =
      if nombre == "" do
        ["Paleta línea #{linea}: el nombre está vacío" | errores]
      else
        errores
      end

    errores =
      if color_valido?(hex) do
        errores
      else
        ["Paleta línea #{linea}: el color '#{hex}' no tiene la forma #RRGGBB" | errores]
      end

    if Map.has_key?(simbolos, simbolo) do
      primera = Map.get(simbolos, simbolo)
      error = "Paleta línea #{linea}: el símbolo '#{simbolo}' está repetido (ya estaba en la línea #{primera})"
      revisar_paleta(resto, simbolos, [error | errores])
    else
      revisar_paleta(resto, Map.put(simbolos, simbolo, linea), errores)
    end
  end

  defp revisar_paleta([{campos, linea} | resto], simbolos, errores) do
    error = "Paleta línea #{linea}: se esperaban 3 campos (simbolo,nombre,color_hex) y hay #{length(campos)}"
    revisar_paleta(resto, simbolos, [error | errores])
  end

  # Un color válido es '#' seguido de exactamente 6 dígitos hexadecimales.
  defp color_valido?(hex) do
    case String.graphemes(hex) do
      ["#" | digitos] -> length(digitos) == 6 and todos_hex?(digitos)
      _ -> false
    end
  end

  defp todos_hex?([]), do: true

  defp todos_hex?([c | resto]) do
    String.contains?("0123456789abcdefABCDEF", c) and todos_hex?(resto)
  end

  # ---------------------------------------------------------------- mapa

  defp quitar_vacias_al_inicio([{[], _linea} | resto]), do: quitar_vacias_al_inicio(resto)
  defp quitar_vacias_al_inicio(filas), do: filas

  defp quitar_vacias_al_final(filas) do
    filas |> invertir() |> quitar_vacias_al_inicio() |> invertir()
  end

  # Revisa que ninguna fila esté vacía y que todas tengan el mismo largo.
  defp revisar_filas([], _ancho, _fila, errores), do: errores

  defp revisar_filas([{simbolos, linea} | resto], ancho, fila, errores) do
    cond do
      simbolos == [] ->
        error = "Mapa fila #{fila} (línea #{linea}): la fila está vacía"
        revisar_filas(resto, ancho, fila + 1, [error | errores])

      length(simbolos) != ancho ->
        error = "Mapa fila #{fila} (línea #{linea}): tiene #{length(simbolos)} casillas y se esperaban #{ancho}"
        revisar_filas(resto, ancho, fila + 1, [error | errores])

      true ->
        revisar_filas(resto, ancho, fila + 1, errores)
    end
  end

  # Revisa fila por fila y columna por columna que el símbolo esté en la paleta.
  defp revisar_simbolos([], _paleta, _fila, errores), do: errores

  defp revisar_simbolos([{simbolos, linea} | resto], paleta, fila, errores) do
    errores = revisar_columnas(simbolos, paleta, fila, 0, linea, errores)
    revisar_simbolos(resto, paleta, fila + 1, errores)
  end

  defp revisar_columnas([], _paleta, _fila, _columna, _linea, errores), do: errores

  defp revisar_columnas([simbolo | resto], paleta, fila, columna, linea, errores) do
    errores =
      if Map.has_key?(paleta, simbolo) do
        errores
      else
        ["Mapa fila #{fila}, columna #{columna} (línea #{linea}): el símbolo '#{simbolo}' no está en la paleta" | errores]
      end

    revisar_columnas(resto, paleta, fila, columna + 1, linea, errores)
  end

  # Invierte una lista sin usar Enum.reverse.
  defp invertir(lista), do: invertir(lista, [])
  defp invertir([], acumulado), do: acumulado
  defp invertir([x | resto], acumulado), do: invertir(resto, [x | acumulado])
end
