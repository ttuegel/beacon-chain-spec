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
      <justified> .Map </justified> // Epoch -> Block option
      <finalized> .Map </finalized> // Epoch -> Block option
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
         <validators>
           90000 |-> #Validator(90000,1)
           90001 |-> #Validator(90001,1)
           90002 |-> #Validator(90002,1)
           90003 |-> #Validator(90003,1)
           90004 |-> #Validator(90004,1)
           90005 |-> #Validator(90005,1)
           90006 |-> #Validator(90006,1)
         </validators>
         <attested> 0 |-> .Attestations </attested>
         <justified> 0 |-> some 0 </justified>
         <finalized> 0 |-> some 0 </finalized>
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
       <state> <slot> Slot        </slot> S </state>
     (
       .Bag
     =>
       <state> <slot> Slot +Int 1 </slot> S </state>
     )
       ...
     </states>
     requires Slot <Int TargetSlot

rule <k> processSlots(TargetSlot) => . ... </k>
     <currentSlot> Slot </currentSlot>
     requires Slot ==Int TargetSlot

rule <k> processSlot() => . ... </k>

rule <k> processBlock(#Block((Slot, ID), Parent, Attestations))
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
       <lastBlock> Parent => (Slot, ID) </lastBlock>
       ...
     </state>

syntax KItem ::= processAttestations(Attestations)
rule <k> processAttestations(A Attestations => Attestations) ... </k>
     <currentSlot> Slot </currentSlot>
     <state>
       <slot> Slot </slot>
       <attested>
         A.target_epoch |-> (As:Attestations => A As)
         ...
       </attested>
       ...
     </state>
     <state>
       <slot> firstSlotOf(A.target_epoch) </slot>
       <lastJustified> (JEpoch, JBlock) </lastJustified>
       ...
     </state>
     requires A.source_epoch ==Int JEpoch
      andBool A.source_block ==Int JBlock
      andBool A.slot +Int MIN_ATTESTATION_INCLUSION_DELAY <=Int Slot andBool Slot <=Int A.slot +Int MAX_ATTESTATION_INCLUSION_DELAY
      //TODO: check if A.attester is assigned to A.slot
rule processAttestations(.Attestations) => .

rule <k> processEpoch()
      => processJustification(epochOf(Slot) -Int 2)
      ~> processJustification(epochOf(Slot) -Int 1)
      ~> processFinalization(epochOf(Slot) -Int 2)
      ~> processFinalization(epochOf(Slot) -Int 1) ... </k>
     <currentSlot> Slot </currentSlot>
     <state>
       <slot> Slot </slot>
       <attested> A => A[epochOf(Slot) <- .Attestations] </attested>
       <justified> J => J[epochOf(Slot) <- none] </justified>
       <finalized> F => F[epochOf(Slot) <- none] </finalized>
       ...
     </state>
     requires isFirstSlotOfEpoch(Slot)

rule <k> processEpoch() => . ... </k>
     <currentSlot> Slot </currentSlot>
     requires notBool isFirstSlotOfEpoch(Slot)

syntax KItem ::= processJustification(Int)
rule <k> processJustification(Epoch)
      => isJustifiable(EpochBoundaryBlock, Attestations, Validators)
      ~> justify(Epoch, EpochBoundaryBlock) ... </k>
     <currentSlot> Slot </currentSlot>
     <state>
       <slot> Slot </slot>
       <attested>
         Epoch |-> Attestations:Attestations
         ...
       </attested>
     //<validators> Validators </validators> // TODO: which validators to be considered?
       ...
     </state>
     <state>
       <slot> firstSlotOf(Epoch) </slot>
       <lastBlock> (_, EpochBoundaryBlock) </lastBlock>
       <validators> Validators </validators> // TODO: which validators to be considered?
       ...
     </state>
     requires Epoch >=Int 1
rule <k> processJustification(Epoch) => . ... </k>
     requires Epoch <Int 1

syntax Bool ::= isJustifiable(Int, Attestations, Map) [function]
rule isJustifiable(EpochBoundaryBlock, Attestations, Validators)
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
       <justified> Epoch |-> (none => some BlockID) ... </justified>
       <lastJustified> _ => (Epoch, BlockID) </lastJustified>
       ...
     </state>
// can be justified multiple times
rule <k> true ~> justify(Epoch,BlockID) => . ... </k>
     <currentSlot> Slot </currentSlot>
     <state>
       <slot> Slot </slot>
       <justified> Epoch |-> some BlockID ... </justified>
       <lastJustified> (Epoch, BlockID) </lastJustified>
       ...
     </state>
rule <k> false ~> justify(_,_) => . ... </k>

syntax KItem ::= processFinalization(Int)
rule <k> processFinalization(TargetEpoch)
      => isFinalizable(SourceEpoch, TargetEpoch, Justified)
      ~> finalize(SourceEpoch, SourceBlock) ... </k>
     <currentSlot> Slot </currentSlot>
     <state>
       <slot> Slot </slot>
       <justified> Justified </justified>
       ...
     </state>
     <state>
       <slot> firstSlotOf(TargetEpoch) </slot>
       <lastJustified> (SourceEpoch, SourceBlock) </lastJustified>
       ...
     </state>
     requires TargetEpoch >=Int 1
rule <k> processFinalization(TargetEpoch) => . ... </k>
     requires TargetEpoch <Int 1

// source : source+1 = target justified
// source : source+1 : source+2 = target justified
syntax Bool ::= isFinalizable(Int, Int, Map) [function]
rule isFinalizable(SourceEpoch, TargetEpoch, Justified)
  => isJustified(SourceEpoch, Justified) andBool isJustified(TargetEpoch, Justified)
     andBool (
                SourceEpoch +Int 1 ==Int TargetEpoch
       orBool ( SourceEpoch +Int 2 ==Int TargetEpoch andBool isJustified(SourceEpoch +Int 1, Justified) )
     )

syntax Bool ::= isJustified(Int, Map) [function]
rule isJustified(Epoch, Epoch |-> (some _) _:Map) => true
rule isJustified(Epoch, Epoch |-> none     _:Map) => false

syntax KItem ::= finalize(Int, Int)
rule <k> true ~> finalize(Epoch, BlockID) => . ... </k>
     <currentSlot> Slot </currentSlot>
     <state>
       <slot> Slot </slot>
       <finalized> Epoch |-> (none => some BlockID) ... </finalized>
       <lastFinalized> _ => (Epoch, BlockID) </lastFinalized>
       ...
     </state>
// can be finalized multiple times
rule <k> true ~> finalize(Epoch, BlockID) => . ... </k>
     <currentSlot> Slot </currentSlot>
     <state>
       <slot> Slot </slot>
       <finalized> Epoch |-> some BlockID ... </finalized>
       <lastFinalized> (Epoch, BlockID) </lastFinalized>
       ...
     </state>
rule <k> false ~> finalize(_, _) => . ... </k>

endmodule
