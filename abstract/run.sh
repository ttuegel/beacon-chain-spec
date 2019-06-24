  set -e

  rm -rf abstract-beacon-chain-kompiled/
  kompile --backend java abstract-beacon-chain.k
  krun --smt none test1.abc | diff - test1.abc.out
  krun --smt none test2.abc | diff - test2.abc.out
  krun --smt none test3.abc | diff - test3.abc.out

# krun --smt none test1.abc >test1.abc.out
# krun --smt none test2.abc >test2.abc.out
# krun --smt none test3.abc >test3.abc.out
