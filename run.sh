  set -e

# rm -rf beacon-chain-kompiled/
# kompile --backend java beacon-chain.k
# krun --smt none 0.beacon-chain | diff - 0.beacon-chain.out

  rm -rf abstract-beacon-chain-kompiled/
  kompile --backend java abstract-beacon-chain.k
  krun --smt none test1.abc | diff - test1.abc.out
