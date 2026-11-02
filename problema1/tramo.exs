# Programación III - Parcial 2 - Problema 1
# Struct de un tramo de transporte dirigido.

defmodule Tramo do
  @moduledoc """
  Un tramo va de `origen` a `destino` y tiene un tiempo en minutos y un costo.
  También guardamos la línea física y el texto original para los reportes.
  """

  defstruct origen: nil, destino: nil, minutos: 0, costo: 0, linea: 0, texto: ""

  @doc """
  Convierte `{texto, linea}` en `{:ok, %Tramo{}}` o `{:error, motivo}`.
  El formato esperado es `origen,destino,minutos,costo`.
  """
  def parse({texto, linea}) do
    campos = texto |> String.split(",") |> Enum.map(&String.trim/1)

    case campos do
      [origen, destino, minutos, costo] ->
        with :ok <- revisar_centro(origen, "origen"),
             :ok <- revisar_centro(destino, "destino"),
             {:ok, minutos} <- entero_positivo(minutos, "minutos"),
             {:ok, costo} <- entero_positivo(costo, "costo") do
          {:ok,
           %Tramo{
             origen: origen,
             destino: destino,
             minutos: minutos,
             costo: costo,
             linea: linea,
             texto: texto
           }}
        end

      _ ->
        {:error, "se esperaban 4 campos (origen,destino,minutos,costo) y hay #{length(campos)}"}
    end
  end

  defp revisar_centro("", nombre), do: {:error, "el #{nombre} está vacío"}
  defp revisar_centro(_centro, _nombre), do: :ok

  defp entero_positivo(texto, nombre) do
    case Integer.parse(texto) do
      {numero, ""} when numero > 0 -> {:ok, numero}
      {_numero, ""} -> {:error, "#{nombre} debe ser mayor que cero (#{texto})"}
      _ -> {:error, "#{nombre} no es un entero (#{texto})"}
    end
  end

  @doc "Texto corto del tramo para los reportes, por ejemplo `A → B (8 min, costo 5)`."
  def describir(tramo) do
    "#{tramo.origen} → #{tramo.destino} (#{tramo.minutos} min, costo #{tramo.costo})"
  end
end
