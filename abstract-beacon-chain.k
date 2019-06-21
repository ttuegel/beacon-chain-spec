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

syntax Attestations ::= List{Attestation,""}
syntax Attestation  ::= #Attestation(Int,Int,Int,Int) // source epoch/block, target epoch/block

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
rule <k> stateTransition(#Block(NewBlockSlot,Parent,Attestations))
      => processSlots(NewBlockSlot)
      ~> processBlock(#Block(NewBlockSlot,Parent,Attestations)) ... </k>
     <slot> Slot </slot>
     requires Slot <Int NewBlockSlot

rule <k> (. => processEpoch())
      ~> processSlots(TargetSlot) ... </k>
     <slot> Slot => Slot +Int 1 </slot>
     requires Slot <Int TargetSlot

rule <k> processSlots(TargetSlot) => . ... </k>
     <slot> Slot </slot>
     requires Slot ==Int TargetSlot

// TODO:
rule <k> processBlock(#Block(Slot,Parent,Attestations)) => . ... </k>
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

rule <k> processEpoch() => TODO ... </k>
     <slot> Slot </slot>
     requires Slot %Int SLOTS_PER_EPOCH ==Int 0 // Slot is the first slot of an epoch

rule <k> processEpoch() => . ... </k>
     <slot> Slot </slot>
     requires Slot %Int SLOTS_PER_EPOCH =/=Int 0

endmodule
