# Programación III - Parcial 2 - Problema 2: Regiones en un mapa de colores y exportación SVG
#
# Uso:
#   elixir main.exs              -> usa mapa.txt y paleta.csv de esta carpeta
#   elixir main.exs CARPETA      -> usa los archivos de CARPETA (por ejemplo casos/invalido)
#
# Las salidas se escriben en la misma carpeta de las entradas.

Code.require_file("../comun.exs", __DIR__)
Code.require_file("color.exs", __DIR__)
Code.require_file("region.exs", __DIR__)
Code.require_file("validacion.exs", __DIR__)
Code.require_file("regiones.exs", __DIR__)
Code.require_file("svg.exs", __DIR__)

defmodule Main do
  @entradas ["mapa.txt", "paleta.csv"]
  @salidas ["regiones.csv", "mapa_regiones.svg", "resumen_regiones.txt"]

  def ejecutar(args) do
    carpeta =
      case args do
        [carpeta | _] -> Path.expand(carpeta)
        [] -> __DIR__
      end

    IO.puts("Problema 2 - Regiones del mapa (carpeta: #{carpeta})\n")

    case Comun.verificar_archivos(carpeta, @entradas) do
      :ok ->
        procesar(carpeta)

      {:error, faltantes} ->
        Enum.each(faltantes, fn nombre -> IO.puts("Falta el archivo requerido: #{nombre}") end)
        IO.puts("No se puede continuar sin esos archivos.")
    end
  end

  defp procesar(carpeta) do
    ruta = fn nombre -> Path.join(carpeta, nombre) end

    # Lectura perezosa. En el mapa dejamos las líneas en blanco para poder
    # avisar si hay una fila vacía en medio del mapa.
    {:ok, lineas_mapa} = Comun.leer_lineas(ruta.("mapa.txt"), false)
    {:ok, lineas_paleta} = Comun.leer_lineas(ruta.("paleta.csv"))

    filas =
      lineas_mapa
      |> Stream.map(fn {texto, linea} -> {String.split(texto), linea} end)
      |> Enum.to_list()

    paleta =
      lineas_paleta
      |> Stream.map(fn {texto, linea} ->
        {texto |> String.split(",") |> Enum.map(&String.trim/1), linea}
      end)
      |> Enum.to_list()

    case Validacion.validar(filas, paleta) do
      {:ok, filas} ->
        Comun.escribir_lineas(ruta.("validacion_mapa.txt"), ["Mapa y paleta válidos. No se encontraron problemas."])
        calcular(ruta, filas, Color.desde_lineas(paleta))

      {:error, errores} ->
        Comun.escribir_lineas(ruta.("validacion_mapa.txt"), errores)

        # Borramos salidas viejas para que no queden resultados de otra ejecución.
        Enum.each(@salidas, fn nombre -> File.rm(ruta.(nombre)) end)

        IO.puts("Se encontraron #{length(errores)} problemas en el mapa o la paleta:")
        Enum.each(errores, fn e -> IO.puts("  - " <> e) end)
        IO.puts("\nNo se calcularon regiones ni SVG. Detalle en validacion_mapa.txt")
    end
  end

  defp calcular(ruta, filas, paleta) do
    num_filas = length(filas)
    {primera, _linea} = hd(filas)
    num_columnas = length(primera)

    mapa = Regiones.armar_mapa(filas)
    regiones = Regiones.encontrar(mapa, num_filas, num_columnas)

    # regiones.csv: una línea por región, escrita a medida que se recorre.
    lineas = Stream.concat(["id;simbolo;area;perimetro;desde;hasta"], Stream.map(regiones, &linea_csv/1))
    Comun.escribir_lineas(ruta.("regiones.csv"), lineas)

    Svg.escribir(ruta.("mapa_regiones.svg"), mapa, num_filas, num_columnas, paleta, regiones)

    resumen = resumen(regiones, num_filas, num_columnas)
    Comun.escribir_lineas(ruta.("resumen_regiones.txt"), resumen)
    Enum.each(resumen, &IO.puts/1)

    IO.puts("\nArchivos generados: regiones.csv, mapa_regiones.svg, resumen_regiones.txt, validacion_mapa.txt")
  end

  defp linea_csv(r) do
    "#{r.id};#{r.simbolo};#{r.area};#{r.perimetro};#{Region.coordenada(r.desde)};#{Region.coordenada(r.hasta)}"
  end

  defp resumen(regiones, num_filas, num_columnas) do
    general = [
      "Mapa de #{num_filas} filas x #{num_columnas} columnas",
      "Número de regiones: #{length(regiones)}"
    ]

    if regiones == [] do
      general ++ ["El mapa solo tiene fondo, no hay regiones."]
    else
      mayor_area = Regiones.maximas(regiones, :area)
      mayor_perimetro = Regiones.maximas(regiones, :perimetro)

      general ++
        ["Mayor área (#{hd(mayor_area).area} casillas):"] ++
        Enum.map(mayor_area, &describir/1) ++
        ["Mayor perímetro (#{hd(mayor_perimetro).perimetro} lados):"] ++
        Enum.map(mayor_perimetro, &describir/1)
    end
  end

  defp describir(r) do
    "  Región #{r.id} (#{r.simbolo}): área #{r.area}, perímetro #{r.perimetro}, " <>
      "desde #{Region.coordenada(r.desde)} hasta #{Region.coordenada(r.hasta)}"
  end
end

Main.ejecutar(System.argv())
