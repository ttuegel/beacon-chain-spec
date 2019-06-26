module ABSTRACT-BEACON-CHAIN-SYNTAX
imports INT

// libraries
syntax Int ::= hash(Int) [function, smtlib(hash)]

// functions
syntax Cmd ::= stateTransition(Block)
             | processSlots(Int)
             | processSlot()
             | processBlock(Block)
             | processEpoch()

// program
syntax Cmds ::= Cmd Cmds | Cmd
rule C:Cmd Cs:Cmds => C ~> Cs

// data structures
syntax Pair ::= "(" Int "," Int ")"
syntax Option ::= "none" | "some" Int

syntax Block ::= #Block(Pair,Pair,Attestations,Deposits) // (slot,id), parent, attestations, deposits
syntax Int          ::= Block ".slot"         [function]
syntax Int          ::= Block ".id"           [function]
syntax Pair         ::= Block ".parent"       [function]
syntax Attestations ::= Block ".attestations" [function]
syntax Deposits     ::= Block ".deposits"     [function]
rule #Block((X,_),_,_,_).slot         => X
rule #Block((_,X),_,_,_).id           => X
rule #Block((_,_),X,_,_).parent       => X
rule #Block((_,_),_,X,_).attestations => X
rule #Block((_,_),_,_,X).deposits     => X

syntax Attestations ::= List{Attestation,""}
syntax Attestation  ::= #Attestation(Int,Int,Pair,Pair) // attester, assigned slot, source epoch/block, target epoch/block
syntax Int ::= Attestation ".attester"     [function]
syntax Int ::= Attestation ".slot"         [function]
syntax Int ::= Attestation ".source_epoch" [function]
syntax Int ::= Attestation ".source_block" [function]
syntax Int ::= Attestation ".target_epoch" [function]
syntax Int ::= Attestation ".target_block" [function]
rule #Attestation(X,_,(_,_),(_,_)).attester     => X
rule #Attestation(_,X,(_,_),(_,_)).slot         => X
rule #Attestation(_,_,(X,_),(_,_)).source_epoch => X
rule #Attestation(_,_,(_,X),(_,_)).source_block => X
rule #Attestation(_,_,(_,_),(X,_)).target_epoch => X
rule #Attestation(_,_,(_,_),(_,X)).target_block => X

syntax Validator ::= #Validator(Int,Pair,Pair,Pair) // id, (balance, effective_balance), join epoch (eligible, actual), exit epoch (eligible, actual)
syntax Int ::= Validator ".id"                  [function]
syntax Int ::= Validator ".balance"             [function]
syntax Int ::= Validator ".effective_balance"   [function]
syntax Int ::= Validator ".join_epoch_eligible" [function]
syntax Int ::= Validator ".join_epoch_actual"   [function]
syntax Int ::= Validator ".exit_epoch_eligible" [function]
syntax Int ::= Validator ".exit_epoch_actual"   [function]
rule #Validator(X,(_,_),(_,_),(_,_)).id                  => X
rule #Validator(_,(X,_),(_,_),(_,_)).balance             => X
rule #Validator(_,(_,X),(_,_),(_,_)).effective_balance   => X
rule #Validator(_,(_,_),(X,_),(_,_)).join_epoch_eligible => X
rule #Validator(_,(_,_),(_,X),(_,_)).join_epoch_actual   => X
rule #Validator(_,(_,_),(_,_),(X,_)).exit_epoch_eligible => X
rule #Validator(_,(_,_),(_,_),(_,X)).exit_epoch_actual   => X

syntax Deposits ::= List{Deposit,""}
syntax Deposit  ::= #Deposit(Int,Int) // sender, amount
syntax Int ::= Deposit ".sender" [function]
syntax Int ::= Deposit ".amount" [function]
rule #Deposit(X,_).sender => X
rule #Deposit(_,X).amount => X

// macros
syntax Int ::= "SLOTS_PER_EPOCH"                  rule SLOTS_PER_EPOCH                 =>      4 /* 64 */       [macro]
syntax Int ::= "MIN_ATTESTATION_INCLUSION_DELAY"  rule MIN_ATTESTATION_INCLUSION_DELAY =>      1 /*  4 */       [macro]
syntax Int ::= "MAX_ATTESTATION_INCLUSION_DELAY"  rule MAX_ATTESTATION_INCLUSION_DELAY => SLOTS_PER_EPOCH       [macro]
syntax Int ::= "FAR_FUTURE_EPOCH"                 rule FAR_FUTURE_EPOCH                => 999999 /* 2^64 - 1 */ [macro]
syntax Int ::= "MIN_DEPOSIT_AMOUNT"               rule MIN_DEPOSIT_AMOUNT              =>      1 /*  1 */       [macro]
syntax Int ::= "MAX_EFFECTIVE_BALANCE"            rule MAX_EFFECTIVE_BALANCE           =>      2 /* 32 */       [macro]
syntax Int ::= "EFFECTIVE_BALANCE_INCREMENT"      rule EFFECTIVE_BALANCE_INCREMENT     =>      1 /*  1 */       [macro]

syntax Int ::= epochOf(Int)     [function]
             | firstSlotOf(Int) [function]
             | lastSlotOf(Int)  [function]
syntax Bool ::= isFirstSlotOfEpoch(Int) [function]
rule epochOf(Slot) => Slot /Int SLOTS_PER_EPOCH
rule firstSlotOf(Epoch) => Epoch *Int SLOTS_PER_EPOCH
rule lastSlotOf(Epoch) => firstSlotOf(Epoch) +Int SLOTS_PER_EPOCH -Int 1
rule isFirstSlotOfEpoch(Slot) => Slot %Int SLOTS_PER_EPOCH ==Int 0 // Slot is the first slot of an epoch?

endmodule
