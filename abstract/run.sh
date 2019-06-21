  set -e

  rm -rf abstract-beacon-chain-kompiled/
  kompile --backend java abstract-beacon-chain.k
  krun --smt none test1.abc | diff - test1.abc.out
# krun --smt none test1.abc > test1.abc.out
