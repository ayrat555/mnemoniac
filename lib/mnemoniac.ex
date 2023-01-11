defmodule Mnemoniac do
  @moduledoc """
  Mnemoniac is an implementation of BIP-39 which describes generation of mnemonic codes or mnemonic sentences - a group of easy to remember words - for the generation of deterministic wallets.

  See https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki
  """
  @word_numbers_to_entropy_bits %{12 => 128, 15 => 160, 18 => 192, 21 => 224, 24 => 256}
  @word_numbers Map.keys(@word_numbers_to_entropy_bits)
  @entropy_bits_sizes Map.values(@word_numbers_to_entropy_bits)
  @words :mnemoniac
         |> :code.priv_dir()
         |> Path.join("words")
         |> File.stream!()
         |> Stream.map(&String.trim/1)
         |> Enum.to_list()

  @spec create_mnemonic(non_neg_integer()) :: {:ok, String.t()} | {:error, :invalid_number}
  def create_mnemonic(word_number \\ Enum.max(@word_numbers))

  def create_mnemonic(word_number) when word_number not in @word_numbers do
    {:error, :invalid_number}
  end

  def create_mnemonic(word_number) do
    entropy_bits = Map.fetch!(@word_numbers_to_entropy_bits, word_number)

    mnemonic =
      entropy_bits
      |> create_entropy()
      |> do_create_from_entropy(entropy_bits)

    {:ok, mnemonic}
  end

  @spec create_mnemonic!(non_neg_integer()) :: String.t() | no_return()
  def create_mnemonic!(word_number \\ Enum.max(@word_numbers)) do
    case create_mnemonic(word_number) do
      {:ok, mnemonic} ->
        mnemonic

      _ ->
        raise ArgumentError,
          message:
            "Number of words #{inspect(word_number)} is not supported, please use one of the #{inspect(@word_numbers)}"
    end
  end

  @spec create_mnemonic_from_entropy(binary()) :: {:ok, String.t()} | {:error, :invalid_entropy}
  def create_mnemonic_from_entropy(entropy) do
    found_entropy_bits =
      Enum.find(@word_numbers_to_entropy_bits, fn {_number, bits} ->
        div(bits, 8) == byte_size(entropy)
      end)

    case found_entropy_bits do
      {_, entropy_bits} ->
        mnemonic = do_create_from_entropy(entropy, entropy_bits)

        {:ok, mnemonic}

      _ ->
        {:error, :invalid_entropy}
    end
  end

  @spec create_mnemonic_from_entropy!(binary()) :: String.t() | no_return
  def create_mnemonic_from_entropy!(entropy) do
    case create_mnemonic_from_entropy(entropy) do
      {:ok, mnemonic} ->
        mnemonic

      _ ->
        raise ArgumentError,
          message: "Entropy size is invalid"
    end
  end

  @spec words() :: [String.t()]
  def words, do: @words

  @spec word_numbers_to_entropy_bits() :: %{non_neg_integer() => non_neg_integer()}
  def word_numbers_to_entropy_bits, do: @word_numbers_to_entropy_bits

  @spec word_numbers() :: [non_neg_integer()]
  def word_numbers, do: @word_numbers

  @spec entropy_bit_sizes() :: [non_neg_integer()]
  def entropy_bit_sizes, do: @entropy_bits_sizes

  defp do_create_from_entropy(entropy, entropy_bits) do
    entropy
    |> append_checksum(entropy_bits)
    |> to_mnemonic()
  end

  defp create_entropy(entropy_bits) do
    entropy_bits
    |> div(8)
    |> :crypto.strong_rand_bytes()
  end

  defp append_checksum(entropy, entropy_bits) do
    checksum_size = div(entropy_bits, 32)
    <<checksum::bits-size(checksum_size), _::bits>> = :crypto.hash(:sha256, entropy)

    <<entropy::bits, checksum::bits>>
  end

  defp to_mnemonic(bytes) do
    words =
      for <<chunk::size(11) <- bytes>> do
        Enum.at(@words, chunk)
      end

    Enum.join(words, " ")
  end
end
