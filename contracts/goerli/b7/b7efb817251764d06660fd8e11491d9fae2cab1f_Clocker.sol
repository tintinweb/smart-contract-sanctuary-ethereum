/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

pragma solidity 0.8.17;

contract Clocker {
   
   address public owner;
   uint public HostBlockNumber;
   uint public ClockerBlockNumber;

   constructor(uint _clockerBlockNumber) {
      owner = msg.sender;
      ClockerBlockNumber = _clockerBlockNumber;
   }

   struct Event {
      string DoveID;
      uint TimeObserved;
      bytes32 EventKey;
      
      string ChainName;
      uint EventType;  // 0 or 1

      uint BlockNumber;
      uint BlockTime;

      address Contract;
      string EventName; // e.g. "swap"

      bytes32 ExtraData;
      bytes Signature;
   }

   struct Block {
      uint BlockCreateTime;     // when created by the miner
      //uint ClockerBlockNumber;  // automatically assigned
      //bytes32 BlockHash;
      
      bytes32[] EventKeys;
   }

   mapping (bytes32 => Event) Events;
   mapping (uint => Block) Blocks;

   event NewBlock(uint ClockerBlockNumber);
   event StoredEvents(bytes32[] Keys);

   function getBlockNumber() public view returns(uint) {
      return ClockerBlockNumber;
   }

   function getBlock(uint clockerBlockNumber) public view returns (Block memory) {
      require(
         Blocks[clockerBlockNumber].BlockCreateTime > 0,
         'Invalid BlockNumber'
      );
      return Blocks[clockerBlockNumber];
   }

   function getEvent(bytes32 eventKey) public view returns (Event memory) {
      require(
         Events[eventKey].TimeObserved > 0,
         'Invalid EventKey'
      );
      return Events[eventKey];
   }

   function proposeBlock(uint blockCreateTime, Event[] memory ets) public returns (uint) {
      
      // enforce zero or one clocker blocks per host block
      require(
         block.number > HostBlockNumber,
         'Already a Clocker block in this host block'
      );

      // enforce at least one event
      require(ets.length > 0, 'No event');

      bytes32[] memory _keys;
      _keys = new bytes32[](ets.length);

      for (uint8 i = 0; i < ets.length; ++i) {
         // check for duplicates in the chain
         require(Events[ets[i].EventKey].TimeObserved == 0, 'Duplicate Event');
         if (i > 0) {
            // enforce time ordering
            require(ets[i].TimeObserved >= ets[i-1].TimeObserved, 'Break in Time Continuum');
         }
         // prepare keys array
         _keys[i] = ets[i].EventKey;
         // save the event
         // this is important to do here so duplicate events within the proposed block 
         // do not sneak through the duplicate event require
         Events[ets[i].EventKey] = ets[i];
      }

      // create and save the block
      Blocks[ClockerBlockNumber + 1] = Block({
         BlockCreateTime: blockCreateTime, 
         EventKeys: _keys});

      // advance the clocker block number
      ClockerBlockNumber = ClockerBlockNumber + 1;

      // and, finally, update the singularity check
      HostBlockNumber = block.number;

      emit NewBlock(ClockerBlockNumber);

      emit StoredEvents(_keys);

      return ClockerBlockNumber;

   }
}