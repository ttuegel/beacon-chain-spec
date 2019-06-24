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

syntax Block ::= #Block(Pair,Pair,Attestations) // (slot,id), parent, attestations
syntax Int          ::= Block ".slot"         [function]
syntax Int          ::= Block ".id"           [function]
syntax Pair         ::= Block ".parent"       [function]
syntax Attestations ::= Block ".attestations" [function]
rule #Block((X,_),_,_).slot         => X
rule #Block((_,X),_,_).id           => X
rule #Block((_,_),X,_).parent       => X
rule #Block((_,_),_,X).attestations => X

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

syntax Validator ::= #Validator(Int,Int) // id, balance
syntax Int ::= Validator ".id"      [function]
syntax Int ::= Validator ".balance" [function]
rule #Validator(X,_).id      => X
rule #Validator(_,X).balance => X

// macros
syntax Int ::= "SLOTS_PER_EPOCH"                  rule SLOTS_PER_EPOCH                 => 4 /* 64 */      [macro]
syntax Int ::= "MIN_ATTESTATION_INCLUSION_DELAY"  rule MIN_ATTESTATION_INCLUSION_DELAY => 1 /*  4 */      [macro]
syntax Int ::= "MAX_ATTESTATION_INCLUSION_DELAY"  rule MAX_ATTESTATION_INCLUSION_DELAY => SLOTS_PER_EPOCH [macro]

syntax Int ::= epochOf(Int)     [function]
             | firstSlotOf(Int) [function]
             | lastSlotOf(Int)  [function]
syntax Bool ::= isFirstSlotOfEpoch(Int) [function]
rule epochOf(Slot) => Slot /Int SLOTS_PER_EPOCH
rule firstSlotOf(Epoch) => Epoch *Int SLOTS_PER_EPOCH
rule lastSlotOf(Epoch) => firstSlotOf(Epoch) +Int SLOTS_PER_EPOCH -Int 1
rule isFirstSlotOfEpoch(Slot) => Slot %Int SLOTS_PER_EPOCH ==Int 0 // Slot is the first slot of an epoch?

endmodule
