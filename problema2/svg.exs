# Programación III - Parcial 2 - Problema 2
# Exportación del mapa de regiones a SVG.

defmodule Svg do
  @moduledoc """
  Escribe el SVG por partes: primero el encabezado, luego un rectángulo por
  casilla, después los números de región y por último el cierre.
  Cada parte se escribe en el archivo apenas se genera.
  """

  @lado 40

  def escribir(ruta, mapa, num_filas, num_columnas, paleta, regiones) do
    ancho = @lado * num_columnas
    alto = @lado * num_filas

    # Para cada casilla, a qué región pertenece (las de fondo no están).
    region_de =
      Enum.reduce(regiones, %{}, fn r, acc ->
        Enum.reduce(r.celdas, acc, fn pos, acc -> Map.put(acc, pos, r) end)
      end)

    File.open!(ruta, [:write, :utf8], fn archivo ->
      IO.puts(archivo, ~s(<?xml version="1.0" encoding="UTF-8"?>))
      IO.puts(archivo, ~s(<svg xmlns="http://www.w3.org/2000/svg" width="#{ancho}" height="#{alto}" viewBox="0 0 #{ancho} #{alto}">))
      IO.puts(archivo, "<title>Mapa de regiones</title>")

      # Un rectángulo por casilla, incluido el fondo.
      for f <- 0..(num_filas - 1), c <- 0..(num_columnas - 1) do
        simbolo = Map.get(mapa, {f, c})
        color = Map.get(paleta, simbolo)
        IO.puts(archivo, rectangulo(f, c, color, Map.get(region_de, {f, c})))
      end

      # El ID de cada región en su primera casilla (la de arriba a la izquierda).
      Enum.each(regiones, fn r ->
        {f, c} = hd(r.celdas)
        x = c * @lado + div(@lado, 2)
        y = f * @lado + div(@lado, 2)

        IO.puts(
          archivo,
          ~s(<text x="#{x}" y="#{y}" text-anchor="middle" dominant-baseline="central" font-family="sans-serif" font-size="16" font-weight="bold" fill="#000000">#{Comun.escapar_xml(r.id)}</text>)
        )
      end)

      IO.puts(archivo, "</svg>")
    end)
  end

  # El <title> dentro del rect sale como ayuda al pasar el mouse.
  defp rectangulo(f, c, color, region) do
    descripcion =
      case region do
        nil -> "Fondo: #{color.nombre}"
        r -> "Región #{r.id}: #{color.nombre} (#{color.simbolo})"
      end

    ~s(<rect x="#{c * @lado}" y="#{f * @lado}" width="#{@lado}" height="#{@lado}" fill="#{Comun.escapar_xml(color.hex)}" stroke="#333333" stroke-width="1">) <>
      "<title>#{Comun.escapar_xml(descripcion)}</title></rect>"
  end
end
