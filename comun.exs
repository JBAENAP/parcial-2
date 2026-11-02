# Programación III - Parcial 2
# Funciones que usan los dos problemas para leer y escribir archivos.

defmodule Comun do
  @moduledoc """
  Lectura perezosa de archivos de entrada y escritura de salidas línea por línea.
  """

  @doc """
  Abre el archivo con `File.stream!/1` y devuelve `{:ok, stream}` con tuplas
  `{texto, linea_fisica}`. Se quitan los espacios de los extremos y se ignoran
  las líneas que empiezan por `#`. Si `quitar_vacias` es true también se
  ignoran las líneas en blanco.

  Nada se lee todavía: el stream se recorre cuando alguien lo consume.
  """
  def leer_lineas(ruta, quitar_vacias \\ true) do
    if File.exists?(ruta) do
      lineas =
        File.stream!(ruta)
        |> Stream.with_index(1)
        |> Stream.map(fn {texto, numero} -> {String.trim(texto), numero} end)
        |> Stream.reject(fn {texto, _numero} -> String.starts_with?(texto, "#") end)
        |> Stream.reject(fn {texto, _numero} -> quitar_vacias and texto == "" end)

      {:ok, lineas}
    else
      {:error, "No se encontró el archivo requerido: #{ruta}"}
    end
  end

  @doc """
  Revisa que existan todos los archivos de la lista. Devuelve `:ok` o
  `{:error, faltantes}` con los nombres que no están.
  """
  def verificar_archivos(carpeta, nombres) do
    faltantes = Enum.reject(nombres, fn nombre -> File.exists?(Path.join(carpeta, nombre)) end)

    if faltantes == [], do: :ok, else: {:error, faltantes}
  end

  @doc """
  Crea (o reemplaza) el archivo y escribe cada elemento de `lineas` como una
  línea, a medida que se van recorriendo. Así no se arma un único string.
  """
  def escribir_lineas(ruta, lineas) do
    File.open!(ruta, [:write, :utf8], fn archivo ->
      Enum.each(lineas, fn linea -> IO.puts(archivo, linea) end)
    end)
  end

  @doc "Reemplaza los caracteres especiales de XML para poder meter texto en un SVG."
  def escapar_xml(texto) do
    texto
    |> to_string()
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end
end
