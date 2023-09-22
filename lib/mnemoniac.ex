defmodule Mnemoniac do
  @moduledoc """
  Mnemoniac is an implementation of BIP-39 which describes generation of mnemonic codes or mnemonic sentences - a group of easy to remember words - for the generation of deterministic wallets.

  See https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki
  """
  @word_numbers_to_entropy_bits %{
    3 => 32,
    6 => 64,
    12 => 128,
    15 => 160,
    18 => 192,
    21 => 224,
    24 => 256
  }

  @valid_words_count [12, 15, 18, 21, 24]
  @word_numbers Map.keys(@word_numbers_to_entropy_bits)
  @entropy_bits_sizes Map.values(@word_numbers_to_entropy_bits)
  @words :mnemoniac
         |> :code.priv_dir()
         |> Path.join("words")
         |> File.stream!()
         |> Stream.map(&String.trim/1)
         |> Enum.to_list()

  @doc """
  Create a random mnemonic with the provided number of words. By default, the number of words is 24.
  Allowed numbers of words are 3, 6, 12, 15, 18, 24

  ## Examples

      iex> {:ok, mnemonic} = Mnemoniac.create_mnemonic()
      iex> mnemonic |> String.split(" ") |> Enum.count()
      24

      iex> {:ok, mnemonic} = Mnemoniac.create_mnemonic(12)
      iex> mnemonic |> String.split(" ") |> Enum.count()
      12

      iex> Mnemoniac.create_mnemonic(10)
      {:error, :invalid_number}
  """

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

  @doc """
  Similar to `create_mnemonic/1`, but fails the number of words is not supported

  ## Examples

      iex> mnemonic = Mnemoniac.create_mnemonic!()
      iex> mnemonic |> String.split(" ") |> Enum.count()
      24

      iex> mnemonic = Mnemoniac.create_mnemonic!(12)
      iex> mnemonic |> String.split(" ") |> Enum.count()
      12

      iex> Mnemoniac.create_mnemonic!(10)
      ** (ArgumentError) Number of words 10 is not supported, please use one of the [3, 6, 12, 15, 18, 21, 24]
  """
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

  @doc """
  Create a mnemonic from entropy. The supported byte sizes are 16, 20, 24, 32

  ## Examples

      iex> Mnemoniac.create_mnemonic_from_entropy(<<6, 197, 169, 93, 98, 210, 82, 216, 148, 177, 1, 251, 142, 15, 154, 85, 140, 0, 13, 202,234, 160, 129, 218>>)
      {:ok, "almost coil firm shield cement hobby fan cage wine idea track prison scale alone close favorite limb still"}

      iex> Mnemoniac.create_mnemonic_from_entropy(<<6, 197, 169, 93, 98, 210, 82, 216, 148, 177, 1, 251, 142, 15, 154, 85, 140, 0, 13, 202,234, 160, 129, 218, 6, 197, 169, 93, 98, 210, 82, 216>>)
      {:ok, "almost coil firm shield cement hobby fan cage wine idea track prison scale alone close favorite limb south ramp famous stomach hard enter author"}

      iex> Mnemoniac.create_mnemonic_from_entropy(<<1>>)
      {:error, :invalid_entropy}
  """
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

  @doc """
  Similar to `create_mnemonic_from_entropy/1`, but fails the entropy has unsupported byte size

  ## Examples

      iex> Mnemoniac.create_mnemonic_from_entropy!(<<6, 197, 169, 93, 98, 210, 82, 216, 148, 177, 1, 251, 142, 15, 154, 85, 140, 0, 13, 202,234, 160, 129, 218>>)
      "almost coil firm shield cement hobby fan cage wine idea track prison scale alone close favorite limb still"

      iex> Mnemoniac.create_mnemonic_from_entropy!(<<1>>)
      ** (ArgumentError) Entropy size is invalid
  """
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

  @doc """
  Return all 2048 words used for mnemonic generation
  """
  @spec words() :: [String.t()]
  def words, do: @words

  @doc """
  Return a map of word numbers to entropy bits.
  """
  @spec word_numbers_to_entropy_bits() :: %{non_neg_integer() => non_neg_integer()}
  def word_numbers_to_entropy_bits, do: @word_numbers_to_entropy_bits

  @doc """
  Return supported numbers of words that can be used for mnemonic generation
  """
  @spec word_numbers() :: [non_neg_integer()]
  def word_numbers, do: @word_numbers

  @doc """
  Return supported entopy bit sizes
  """
  @spec entropy_bit_sizes() :: [non_neg_integer()]
  def entropy_bit_sizes, do: @entropy_bits_sizes

  @doc """
  Validates a mnemonic

  ## Examples

      iex> Mnemoniac.valid_mnemonic?("leaf bitter canoe cat decade aim history cricket sniff subject culture diamond liberty forest voice thing limb lounge close winner fine cake catalog silent")
      true

      iex> Mnemoniac.valid_mnemonic?("word")
      false

      iex> Mnemoniac.valid_mnemonic?(["muffin", "play", "hurt", "fee", "trip", "crack", "doll", "expose", "make", "social", "learn", "lesson"])
      true
  """

  @spec valid_mnemonic?(String.t() | [String.t()], non_neg_integer() | nil) :: boolean()
  def valid_mnemonic?(mnemonic, number_of_words \\ nil)

  def valid_mnemonic?(mnemonic, number_of_words) when is_binary(mnemonic) do
    mnemonic_words = String.split(mnemonic, " ")

    valid_mnemonic?(mnemonic_words, number_of_words)
  end

  def valid_mnemonic?(mnemonic_words, number_of_words) do
    correct_mnemonic_size?(mnemonic_words, number_of_words) && correct_words?(mnemonic_words)
  end

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

  defp correct_mnemonic_size?(words, mnemonic_size) do
    words_count = Enum.count(words)

    if is_nil(mnemonic_size) do
      words_count in @valid_words_count
    else
      words_count == mnemonic_size
    end
  end

  defp correct_words?(words) do
    Enum.all?(words, fn word -> word in words() end)
  end
end
