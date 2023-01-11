defmodule MnemoniacTest do
  use ExUnit.Case

  alias Cryptopunk.Key
  alias Cryptopunk.Seed

  describe "create/1" do
    test "creates mnemonic" do
      words = Mnemoniac.create_mnemonic()

      assert 24 == words |> String.split() |> Enum.count()
    end

    test "generates different mnemonics" do
      words1 = Mnemoniac.create_mnemonic()
      words2 = Mnemoniac.create_mnemonic()

      assert words1 != words2
    end

    test "fails on invalid word count" do
      assert_raise ArgumentError,
                   "Number of words 10 is not supported, please use one of the [12, 15, 18, 21, 24]",
                   fn ->
                     Mnemoniac.create_mnemonic(10)
                   end
    end

    test "creates mnemonics of different sizes" do
      Enum.each([12, 15, 18, 21, 24], fn number_of_words ->
        assert number_of_words ==
                 number_of_words
                 |> Mnemoniac.create_mnemonic()
                 |> String.split(" ")
                 |> Enum.count()
      end)
    end

    # https://github.com/trezor/python-mnemonic/blob/master/vectors.json
    test "verifies with bip tests" do
      %{"english" => tests} =
        File.read!("test/support/mnemonic_test.json")
        |> Jason.decode!()

      for [entropy, mnemonic, expected_seed, extended_private_key] <- tests do
        {:ok, entropy} = Base.decode16(entropy, case: :lower)
        assert mnemonic == Mnemoniac.create_mnemonic_from_entropy(entropy)

        seed = Seed.create(mnemonic, "TREZOR")
        assert expected_seed == Base.encode16(seed, case: :lower)

        master_private_key = Key.master_key(seed)
        assert extended_private_key == Key.serialize(master_private_key, <<4, 136, 173, 228>>)
      end
    end
  end

  describe "create_from_entropy/2" do
    test "create mnemonic from the provided entropy" do
      bytes =
        <<6, 197, 169, 93, 98, 210, 82, 216, 148, 177, 1, 251, 142, 15, 154, 85, 140, 0, 13, 202,
          234, 160, 129, 218>>

      result = Mnemoniac.create_mnemonic_from_entropy(bytes)

      expected_result =
        "almost coil firm shield cement hobby fan cage wine idea track prison scale alone close favorite limb still"

      assert expected_result == result
    end
  end
end
