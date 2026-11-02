# Programación III - Parcial 2 - Problema 1: Rutas de entrega en una red dirigida
#
# Uso:
#   elixir main.exs              -> usa tramos.csv y consultas.txt de esta carpeta
#   elixir main.exs CARPETA      -> usa los archivos de CARPETA (por ejemplo casos/invalido)
#
# Las salidas se escriben en la misma carpeta de las entradas.

Code.require_file("../comun.exs", __DIR__)
Code.require_file("tramo.exs", __DIR__)
Code.require_file("itinerario.exs", __DIR__)
Code.require_file("depuracion.exs", __DIR__)
Code.require_file("alcance.exs", __DIR__)
Code.require_file("busqueda.exs", __DIR__)

defmodule Main do
  @entradas ["tramos.csv", "consultas.txt"]

  def ejecutar(args) do
    carpeta =
      case args do
        [carpeta | _] -> Path.expand(carpeta)
        [] -> __DIR__
      end

    IO.puts("Problema 1 - Rutas de entrega (carpeta: #{carpeta})\n")

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

    # 1. Leer y convertir los tramos de forma perezosa. El stream se consume
    #    una sola vez en split_with y ahí ya separamos buenos y malos.
    {:ok, lineas} = Comun.leer_lineas(ruta.("tramos.csv"))

    {buenos, malos} =
      lineas
      |> Stream.map(fn linea -> {linea, Tramo.parse(linea)} end)
      |> Enum.split_with(fn {_linea, resultado} -> match?({:ok, _}, resultado) end)

    tramos = Enum.map(buenos, fn {_linea, {:ok, tramo}} -> tramo end)
    escribir_errores(ruta.("errores_tramos.txt"), malos)

    # 2. Validación previa recursiva: quitar bucles y parejas repetidas.
    {tramos_red, descartes} = Depuracion.depurar(tramos)
    escribir_depuracion(ruta.("depuracion_tramos.txt"), descartes)

    IO.puts("Tramos válidos: #{length(tramos)} | con error: #{length(malos)} | descartados en la depuración: #{length(descartes)}")

    # 3. Ahora sí armamos el grafo. Los centros que existen son los que
    #    aparecen en algún tramo bien formado.
    grafo = Busqueda.armar_grafo(tramos_red)

    centros =
      Enum.reduce(tramos, MapSet.new(), fn t, acc ->
        acc |> MapSet.put(t.origen) |> MapSet.put(t.destino)
      end)

    # 4. Resolver cada consulta a medida que se lee del archivo.
    {:ok, consultas} = Comun.leer_lineas(ruta.("consultas.txt"))
    IO.puts("\nItinerarios por consulta:")

    File.open!(ruta.("itinerarios.txt"), [:write, :utf8], fn salida ->
      File.open!(ruta.("alcance_centros.txt"), [:write, :utf8], fn alcance ->
        Enum.each(consultas, fn consulta ->
          resolver_consulta(consulta, grafo, centros, salida, alcance)
        end)
      end)
    end)

    IO.puts("\nArchivos generados en #{carpeta}:")
    IO.puts("  itinerarios.txt, alcance_centros.txt, errores_tramos.txt, depuracion_tramos.txt")
  end

  defp resolver_consulta({texto, linea}, grafo, centros, salida, alcance) do
    case texto |> String.split(",") |> Enum.map(&String.trim/1) do
      [origen, destino] when origen != "" and destino != "" ->
        titulo = "=== #{origen} → #{destino} ==="
        IO.puts(salida, titulo)
        IO.puts(alcance, titulo)

        faltan = Enum.reject([origen, destino], fn c -> MapSet.member?(centros, c) end)

        if faltan != [] do
          mensaje =
            case faltan do
              [centro] -> "El centro #{centro} no existe en la red; no se inicia la búsqueda."
              _ -> "Los centros #{Enum.join(faltan, " y ")} no existen en la red; no se inicia la búsqueda."
            end
          IO.puts(salida, mensaje <> "\n")
          IO.puts(alcance, mensaje <> "\n")
          IO.puts("  #{origen} → #{destino}: #{mensaje}")
        else
          alcanzable = escribir_alcance(alcance, origen, destino, grafo)

          if alcanzable do
            itinerarios = Busqueda.itinerarios(origen, destino, grafo)
            escribir_itinerarios(salida, itinerarios)
            IO.puts("  #{origen} → #{destino}: #{contar(itinerarios)}")
          else
            IO.puts(salida, "Sin itinerarios: #{destino} no es alcanzable desde #{origen}.\n")
            IO.puts("  #{origen} → #{destino}: sin itinerarios")
          end
        end

      _ ->
        mensaje = "Consulta inválida en la línea #{linea}: \"#{texto}\" (se esperaba origen,destino)"
        IO.puts(salida, mensaje <> "\n")
        IO.puts("  " <> mensaje)
    end
  end

  # Consume el stream infinito hasta estabilizar y escribe cada estado.
  # Devuelve true si el destino quedó dentro del último conjunto.
  defp escribir_alcance(archivo, origen, destino, grafo) do
    {estados, paso_estable} = Alcance.hasta_estabilizar(origen, grafo)

    Enum.each(estados, fn {paso, conjunto} ->
      IO.puts(archivo, "Paso #{paso}: #{Alcance.mostrar(conjunto)}")
    end)

    {_paso, final} = List.last(estados)
    alcanzable = MapSet.member?(final, destino)

    IO.puts(archivo, "Se estabiliza en el paso #{paso_estable} (el paso #{paso_estable + 1} repite el mismo conjunto)")
    IO.puts(archivo, "¿#{destino} es alcanzable?: #{if alcanzable, do: "sí", else: "no (sin itinerarios)"}\n")
    alcanzable
  end

  defp escribir_itinerarios(archivo, itinerarios) do
    itinerarios
    |> Enum.with_index(1)
    |> Enum.each(fn {it, n} ->
      IO.puts(archivo, "Itinerario #{n}: #{Itinerario.ruta(it)} | tramos: #{Itinerario.num_tramos(it)} | #{it.minutos} min | costo: #{it.costo}")
      usados = Enum.map(it.tramos, &Tramo.describir/1)
      IO.puts(archivo, "    tramos usados: #{if usados == [], do: "ninguno (origen = destino)", else: Enum.join(usados, "; ")}")
    end)

    IO.puts(archivo, "Total: #{contar(itinerarios)}")

    if itinerarios != [] do
      IO.puts(archivo, "Menos tramos: #{Enum.join(Busqueda.mejores(itinerarios, &Itinerario.num_tramos/1), ", ")}")
      IO.puts(archivo, "Menor tiempo: #{Enum.join(Busqueda.mejores(itinerarios, fn it -> it.minutos end), ", ")}")
      IO.puts(archivo, "Menor costo: #{Enum.join(Busqueda.mejores(itinerarios, fn it -> it.costo end), ", ")}")
    end

    IO.puts(archivo, "")
  end

  defp contar([_uno]), do: "1 itinerario"
  defp contar(itinerarios), do: "#{length(itinerarios)} itinerarios"

  defp escribir_errores(ruta, malos) do
    lineas =
      case malos do
        [] ->
          ["Sin errores de formato."]

        _ ->
          Enum.map(malos, fn {{texto, linea}, {:error, motivo}} ->
            "Línea #{linea}: \"#{texto}\" -> #{motivo}"
          end)
      end

    Comun.escribir_lineas(ruta, lineas)
  end

  defp escribir_depuracion(ruta, descartes) do
    lineas =
      case descartes do
        [] ->
          ["No se descartó ningún tramo."]

        _ ->
          Enum.map(descartes, fn {tramo, motivo} ->
            "Línea #{tramo.linea}: \"#{tramo.texto}\" -> #{motivo}"
          end)
      end

    Comun.escribir_lineas(ruta, lineas)
  end
end

Main.ejecutar(System.argv())
