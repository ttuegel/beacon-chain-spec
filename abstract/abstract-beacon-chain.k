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

module ABSTRACT-BEACON-CHAIN

imports ABSTRACT-BEACON-CHAIN-SYNTAX
imports INT
imports MAP

configuration <T>
  <k> init ~> $PGM:Cmds </k>
  <currentSlot> 0 </currentSlot>
  <states>
    // a state of slot N is the post-state of a (possibly empty) block at slot N
    <state multiplicity="*" type="Map">
      <slot> 0 </slot>
      <validators> .Map </validators> // ValidatorID -> ValidatorState
      <attested> .Map </attested> // Epoch -> Attestations
      <justified> .Map </justified> // Epoch -> Block
      <finalized> .Map </finalized> // Epoch -> Block
      <blocks> // blockchain
        <block multiplicity="*" type="Map">
          <bSlot> 0 </bSlot>
          <parent> 0 </parent> // parent block id
          <attestations> .Attestations </attestations>
          <bID> 0 </bID> // unique block id (e.g., hash)
        </block>
      </blocks>
      <lastBlock> 0 </lastBlock> // last block id
    </state>
  </states>
</T>

syntax KItem ::= "TODO"

syntax KItem ::= "init"
rule <k> init => . ... </k>
     <currentSlot> 0 </currentSlot>
     <states> .Bag =>
       <state>
         <slot> 0 </slot>
         <validators> .Map </validators>
         <attested> 0 |-> .Attestations </attested>
         <justified> .Map </justified>
         <finalized> .Map </finalized>
         <blocks>
           <block>
             <bSlot> 0 </bSlot>
             <parent> -1 </parent>
             <attestations> .Attestations </attestations>
             <bID> 0 </bID>
           </block>
         </blocks>
         <lastBlock> 0 </lastBlock>
       </state>
     </states>

// state_transition
rule <k> stateTransition(Block)
      => processSlots(Block.slot)
      ~> processBlock(Block) ... </k>
     <currentSlot> Slot </currentSlot>
     requires Slot <Int Block.slot

rule <k> (. => processSlot()
            ~> processEpoch())
      ~> processSlots(TargetSlot) ... </k>
     <currentSlot> Slot => Slot +Int 1 </currentSlot>
     <states>
       <state>
         <slot> Slot </slot>
         S
       </state>
     (
       .Bag
     =>
       <state>
         <slot> Slot +Int 1 </slot>
         S
       </state>
     )
       ...
     </states>
     requires Slot <Int TargetSlot

rule <k> processSlots(TargetSlot) => . ... </k>
     <currentSlot> Slot </currentSlot>
     requires Slot ==Int TargetSlot

rule <k> processSlot() => . ... </k>

// TODO:
rule <k> processBlock(#Block(ID,Slot,Parent,Attestations))
      => processAttestations(Attestations) ... </k>
     <currentSlot> Slot </currentSlot>
     <state>
       <slot> Slot </slot>
       <blocks>
       (
         .Bag
       =>
         <block>
           <bSlot> Slot </bSlot>
           <parent> Parent </parent>
           <attestations> Attestations </attestations>
           <bID> ID </bID>
         </block>
       )
         ...
       </blocks>
       <lastBlock> Parent => ID </lastBlock>
       ...
     </state>

syntax KItem ::= processAttestations(Attestations)
rule <k> processAttestations(A As => As) ... </k>
     <currentSlot> Slot </currentSlot>
     <state>
       <slot> Slot </slot>
       <attested>
         A.target_epoch |-> (Atts:Attestations => A Atts)
         ...
       </attested>
       ...
     </state>
rule processAttestations(.Attestations) => .

rule <k> processEpoch() => TODO ... </k>
     <currentSlot> Slot </currentSlot>
     requires Slot %Int SLOTS_PER_EPOCH ==Int 0 // Slot is the first slot of an epoch

rule <k> processEpoch() => . ... </k>
     <currentSlot> Slot </currentSlot>
     requires Slot %Int SLOTS_PER_EPOCH =/=Int 0

endmodule
