module ABSTRACT-BEACON-CHAIN-SYNTAX
imports INT-SYNTAX

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
syntax Block ::= #Block(Int,Int,Int,Attestations) // id, slot, parent, attestations
syntax Int          ::= Block ".id"           [function]
syntax Int          ::= Block ".slot"         [function]
syntax Int          ::= Block ".parent"       [function]
syntax Attestations ::= Block ".attestations" [function]
rule #Block(X,_,_,_).id           => X
rule #Block(_,X,_,_).slot         => X
rule #Block(_,_,X,_).parent       => X
rule #Block(_,_,_,X).attestations => X

syntax Attestations ::= List{Attestation,""}
syntax Attestation  ::= #Attestation(Int,Int,Int,Int) // source epoch/block, target epoch/block
syntax Int ::= Attestation ".source_epoch" [function]
syntax Int ::= Attestation ".source_block" [function]
syntax Int ::= Attestation ".target_epoch" [function]
syntax Int ::= Attestation ".target_block" [function]
rule #Attestation(X,_,_,_).source_epoch => X
rule #Attestation(_,X,_,_).source_block => X
rule #Attestation(_,_,X,_).target_epoch => X
rule #Attestation(_,_,_,X).target_block => X

// macros
syntax Int ::= "SLOTS_PER_EPOCH"  rule SLOTS_PER_EPOCH => 64 [macro]

endmodule
