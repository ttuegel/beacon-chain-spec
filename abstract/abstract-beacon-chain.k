require "abstract-beacon-chain-syntax.k"

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
