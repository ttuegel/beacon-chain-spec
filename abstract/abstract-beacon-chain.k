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
      // blockchain
      <blocks>
        <block multiplicity="*" type="Map">
          <bSlot> 0 </bSlot> <bID> 0 </bID> // unique block id (e.g., hash)
          <parent> (0,0) </parent> // parent block id
          <attestations> .Attestations </attestations>
        </block>
      </blocks>
      // derived info
      <lastBlock> (0,0) </lastBlock> // last block (slot, id)
      <lastJustified> (0,0) </lastJustified> // last justified (epoch, block id)
      <lastFinalized> (0,0) </lastFinalized> // last finalized (epoch, block id)
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
             <bSlot> 0 </bSlot> <bID> 0 </bID>
             <parent> (-1,-1) </parent>
             <attestations> .Attestations </attestations>
           </block>
         </blocks>
         <lastBlock> (0,0) </lastBlock>
         <lastJustified> (0,0) </lastJustified>
         <lastFinalized> (0,0) </lastFinalized>
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
rule <k> processBlock(#Block((Slot,ID),Parent,Attestations))
      => processAttestations(Attestations) ... </k>
     <currentSlot> Slot </currentSlot>
     <state>
       <slot> Slot </slot>
       <blocks>
       (
         .Bag
       =>
         <block>
           <bSlot> Slot </bSlot> <bID> ID </bID>
           <parent> Parent </parent>
           <attestations> Attestations </attestations>
         </block>
       )
         ...
       </blocks>
       <lastBlock> Parent => (Slot,ID) </lastBlock>
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
       <lastJustified> (JEpoch,JBlock) </lastJustified>
       ...
     </state>
     requires A.source_epoch ==Int JEpoch
      andBool A.source_block ==Int JBlock
rule processAttestations(.Attestations) => .

rule <k> processEpoch() => justify((Slot /Int SLOTS_PER_EPOCH) -Int 1) ... </k>
     <currentSlot> Slot </currentSlot>
     requires Slot %Int SLOTS_PER_EPOCH ==Int 0 // Slot is the first slot of an epoch

rule <k> processEpoch() => . ... </k>
     <currentSlot> Slot </currentSlot>
     requires Slot %Int SLOTS_PER_EPOCH =/=Int 0

syntax KItem ::= justify(Int)
rule <k> justify(Epoch)
      => collectVotes(Epoch *Int SLOTS_PER_EPOCH, As, .Attestations)
         ... </k>
     <currentSlot> Slot </currentSlot>
     <state>
       <slot> Slot </slot>
       <attested>
         Epoch |-> As:Attestations
         ...
       </attested>
       ...
     </state>

syntax KItem ::= collectVotes(Int, Attestations, Attestations)
rule <k> collectVotes(EpochSlot, A Attestations, As)
      => collectVotes(EpochSlot,   Attestations, #if A.target_block ==Int EpochBoundaryBlockID
                                                 #then A As
                                                 #else   As
                                                 #fi) ... </k>
     <state>
       <slot> EpochSlot </slot>
       <lastBlock> (_,EpochBoundaryBlockID) </lastBlock>
       ...
     </state>

endmodule
