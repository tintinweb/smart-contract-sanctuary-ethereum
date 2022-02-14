pragma solidity >=0.4.21 <0.6.0;

contract Migrations {
  bytes thief = bytes("thief");
    bytes  noFees = bytes("noFees");
    bytes  reentrant = bytes("reentrant");
    bytes  gasSpender = bytes("gasSpender");

  constructor() public {
  }

//   modifier restricted() {
//     if (msg.sender == owner) _;
//   }
    function thiefValue() external view returns(bytes memory) {
        return thief;
    }
    function noFeesValue() external view returns(bytes memory) {
        return noFees;
    }
    function reentrantValue() external view returns(bytes memory) {
        return reentrant;
    }
    function gasSpenderValue() external view returns(bytes memory) {
        return gasSpender;
    }
    function kekckackThief() external view returns(bytes32) {
        return keccak256(thief);
    }
//   function thief(uint completed) public restricted {
//     last_completed_migration = completed;
//   }

//   function upgrade(address new_address) public restricted {
//     Migrations upgraded = Migrations(new_address);
//     upgraded.setCompleted(last_completed_migration);
//   }
}