defmodule MnemoniacTest do
  use ExUnit.Case
  doctest Mnemoniac

  alias Cryptopunk.Key
  alias Cryptopunk.Seed

  describe "create_mnemonic/1" do
    test "creates mnemonics of different sizes" do
      Enum.each([3, 6, 12, 15, 18, 21, 24], fn number_of_words ->
        assert {:ok, mnemonic} = Mnemoniac.create_mnemonic(number_of_words)

        assert number_of_words == count_words(mnemonic)
      end)
    end

    test "fails to generate a mnemonic if the number of words is invalid" do
      assert {:error, :invalid_number} = Mnemoniac.create_mnemonic(11)
    end
  end

  describe "create_mnemonic!/1" do
    test "creates mnemonic with 24 words by default" do
      mnemonic = Mnemoniac.create_mnemonic!()

      assert 24 == count_words(mnemonic)
    end

    test "generates different mnemonics" do
      words1 = Mnemoniac.create_mnemonic!()
      words2 = Mnemoniac.create_mnemonic!()

      assert words1 != words2
    end

    test "fails on invalid word count" do
      assert_raise ArgumentError,
                   "Number of words 10 is not supported, please use one of the [3, 6, 12, 15, 18, 21, 24]",
                   fn ->
                     Mnemoniac.create_mnemonic!(10)
                   end
    end

    test "creates mnemonics of different sizes" do
      Enum.each([3, 6, 12, 15, 18, 21, 24], fn number_of_words ->
        assert number_of_words ==
                 number_of_words
                 |> Mnemoniac.create_mnemonic!()
                 |> count_words()
      end)
    end
  end

  describe "create_mnemonic_from_entropy!/1" do
    test "create mnemonic from the provided entropy" do
      bytes =
        <<6, 197, 169, 93, 98, 210, 82, 216, 148, 177, 1, 251, 142, 15, 154, 85, 140, 0, 13, 202,
          234, 160, 129, 218>>

      result = Mnemoniac.create_mnemonic_from_entropy!(bytes)

      expected_result =
        "almost coil firm shield cement hobby fan cage wine idea track prison scale alone close favorite limb still"

      assert expected_result == result
    end

    test "fails if entropy is invalid" do
      assert_raise ArgumentError,
                   "Entropy size is invalid",
                   fn ->
                     Mnemoniac.create_mnemonic_from_entropy!(<<1>>)
                   end
    end

    # https://github.com/trezor/python-mnemonic/blob/master/vectors.json
    test "verifies with bip tests" do
      %{"english" => tests} =
        "test/support/mnemonic_test.json"
        |> File.read!()
        |> Jason.decode!()

      for [entropy, mnemonic, expected_seed, extended_private_key] <- tests do
        {:ok, entropy} = Base.decode16(entropy, case: :lower)
        assert mnemonic == Mnemoniac.create_mnemonic_from_entropy!(entropy)

        seed = Seed.create(mnemonic, "TREZOR")
        assert expected_seed == Base.encode16(seed, case: :lower)

        master_private_key = Key.master_key(seed)
        assert extended_private_key == Key.serialize(master_private_key, <<4, 136, 173, 228>>)
      end
    end
  end

  describe "create_mnemonic_from_entropy" do
    test "generates mnemonic from entropies of different sizes" do
      Mnemoniac.word_numbers_to_entropy_bits()
      |> Enum.each(fn {number_of_words, entropy_size} ->
        byte_size = div(entropy_size, 8)
        entropy = :crypto.strong_rand_bytes(byte_size)

        assert {:ok, mnemonic} = Mnemoniac.create_mnemonic_from_entropy(entropy)

        assert number_of_words == count_words(mnemonic)
      end)
    end

    test "fails if entropy bytes is invalid" do
      assert {:error, :invalid_entropy} = Mnemoniac.create_mnemonic_from_entropy(<<1>>)
    end
  end

  describe "words/0" do
    test "returns all words" do
      assert 2048 == Mnemoniac.words() |> Enum.count()
    end
  end

  describe "word_numbers_to_entropy_bits/0" do
    test "returns a map of word numbers to entropy bits" do
      assert %{3 => 32, 6 => 64, 12 => 128, 15 => 160, 18 => 192, 21 => 224, 24 => 256} ==
               Mnemoniac.word_numbers_to_entropy_bits()
    end
  end

  describe "word_numbers/0" do
    test "returns a list of supported word numbers in mnemonic" do
      assert [3, 6, 12, 15, 18, 21, 24] == Mnemoniac.word_numbers()
    end
  end

  describe "entopy_bit_sizes/0" do
    test "returns supported entopy bit sizes" do
      assert [32, 64, 128, 160, 192, 224, 256] == Mnemoniac.entropy_bit_sizes()
    end
  end

  defp count_words(mnemonic) do
    mnemonic
    |> String.split(" ")
    |> Enum.count()
  end
end
