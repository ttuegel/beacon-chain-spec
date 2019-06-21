module ABSTRACT-BEACON-CHAIN-SYNTAX
imports INT-SYNTAX

// libraries
syntax Int ::= hash(Int) [function, smtlib(hash)]

// functions
syntax Cmd ::= stateTransition(Block)
             | processSlots(Int)
             | processBlock(Block)
             | processEpoch()

// program
syntax Cmds ::= Cmd Cmds | Cmd
rule C:Cmd Cs:Cmds => C ~> Cs

// data structures
syntax Block ::= #Block(Int,Int,Attestations) // slot, parent, attestations
syntax Int          ::= Block ".slot"         [function]
syntax Int          ::= Block ".parent"       [function]
syntax Attestations ::= Block ".attestations" [function]
rule #Block(X,_,_).slot         => X
rule #Block(_,X,_).parent       => X
rule #Block(_,_,X).attestations => X

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

module ABSTRACT-BEACON-CHAIN

imports ABSTRACT-BEACON-CHAIN-SYNTAX
imports INT
imports MAP

configuration <T>
  <k> init ~> $PGM:Cmds </k>
  // a state of slot N is the post-state of a block at slot N
  <state>
    <slot> 0 </slot>
    <validators> .Map </validators> // ValidatorID -> ValidatorState
    <attested> .Map </attested> // Epoch -> Attestations
    <justified> .Map </justified> // Epoch -> Block
    <finalized> .Map </finalized> // Epoch -> Block
    <blocks> // blockchain
      <block multiplicity="*" type="Map">
        <bSlot> 0 </bSlot>
        <parent> 0 </parent>
        <attestations> .Attestations </attestations>
      </block>
    </blocks>
    <lastBlock> 0 </lastBlock>
  </state>
  <stateHistory> .List </stateHistory>
</T>

syntax KItem ::= "TODO"

syntax KItem ::= "init"
rule <k> init => . ... </k>
     <attested>
       .Map
     =>
       0 |-> .Attestations
     </attested>
     <blocks>
     (
       .Bag
     =>
       <block>
         <bSlot> 0 </bSlot>
         <parent> -1 </parent>
         <attestations> .Attestations </attestations>
       </block>
     )
       ...
     </blocks>

// state_transition
rule <k> stateTransition(Block)
      => processSlots(Block.slot)
      ~> processBlock(Block) ... </k>
     <slot> Slot </slot>
     requires Slot <Int Block.slot

rule <k> (. => processEpoch())
      ~> processSlots(TargetSlot) ... </k>
     <slot> Slot => Slot +Int 1 </slot>
     requires Slot <Int TargetSlot

rule <k> processSlots(TargetSlot) => . ... </k>
     <slot> Slot </slot>
     requires Slot ==Int TargetSlot

// TODO:
rule <k> processBlock(#Block(Slot,Parent,Attestations))
      => processAttestations(Attestations) ... </k>
     <slot> Slot </slot>
     <blocks>
     (
       .Bag
     =>
       <block>
         <bSlot> Slot </bSlot>
         <parent> Parent </parent>
         <attestations> Attestations </attestations>
       </block>
     )
       ...
     </blocks>
     <lastBlock> Parent => Slot </lastBlock>

syntax KItem ::= processAttestations(Attestations)
rule <k> processAttestations(A As => As) ... </k>
     <attested>
       A.target_epoch |-> (Atts:Attestations => A Atts)
       ...
     </attested>
rule processAttestations(.Attestations) => .

rule <k> processEpoch() => TODO ... </k>
     <slot> Slot </slot>
     requires Slot %Int SLOTS_PER_EPOCH ==Int 0 // Slot is the first slot of an epoch

rule <k> processEpoch() => . ... </k>
     <slot> Slot </slot>
     requires Slot %Int SLOTS_PER_EPOCH =/=Int 0

endmodule
