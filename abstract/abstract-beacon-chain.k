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
      //TODO: check if A.attester is assigned to the slot
rule processAttestations(.Attestations) => .

rule <k> processEpoch()
      => processJustification(epochOf(Slot) -Int 2)
      ~> processJustification(epochOf(Slot) -Int 1) ... </k>
     <currentSlot> Slot </currentSlot>
     requires isFirstSlotOfEpoch(Slot)

rule <k> processEpoch() => . ... </k>
     <currentSlot> Slot </currentSlot>
     requires notBool isFirstSlotOfEpoch(Slot)

syntax KItem ::= processJustification(Int)
rule <k> processJustification(Epoch)
      => isJustifiable(Epoch, EpochBoundaryBlock, As, Validators)
      ~> justify(Epoch, EpochBoundaryBlock) ... </k>
     <currentSlot> Slot </currentSlot>
     <state>
       <slot> Slot </slot>
       <attested>
         Epoch |-> As:Attestations
         ...
       </attested>
     //<validators> Validators </validators> // TODO: which validators to be considered?
       ...
     </state>
     <state>
       <slot> firstSlotOf(Epoch) </slot>
       <lastBlock> (_,EpochBoundaryBlock) </lastBlock>
       <validators> Validators </validators> // TODO: which validators to be considered?
       ...
     </state>

syntax Bool ::= isJustifiable(Int, Int, Attestations, Map) [function]
rule isJustifiable(Epoch, EpochBoundaryBlock, Attestations, Validators)
  => isMajority(attestationsBalance(EpochBoundaryBlock, Attestations, Validators), totalBalance(Validators))

syntax Bool ::= isMajority(Int, Int) [function]
rule isMajority(X, Total) => (X *Int 3) >=Int (Total *Int 2)  // (X / Total) >= 2/3

syntax Int ::= attestationsBalance(Int, Attestations, Map) [function]
rule attestationsBalance(Target, A Attestations, Validators)
  => #if A.target_block ==Int Target
     #then balanceOf(A, Validators)
     #else 0
     #fi +Int attestationsBalance(Target, Attestations, Validators)
rule attestationsBalance(_, .Attestations, _) => 0

syntax Int ::= balanceOf(Attestation, Map) [function]
rule balanceOf(A, A.attester |-> V:Validator _:Map) => V.balance

syntax Int ::= totalBalance(Map) [function]
rule totalBalance(_ |-> V:Validator M:Map) => V.balance +Int totalBalance(M)
rule totalBalance(.Map) => 0

syntax KItem ::= justify(Int, Int)
rule <k> true ~> justify(Epoch,BlockID) => . ... </k>
     <currentSlot> Slot </currentSlot>
     <state>
       <slot> Slot </slot>
       <justified> J => J[Epoch <- BlockID] </justified>
       <lastJustified> _ => (Epoch,BlockID) </lastJustified>
       ...
     </state>
rule <k> false ~> justify(_,_) => . ... </k>

endmodule
