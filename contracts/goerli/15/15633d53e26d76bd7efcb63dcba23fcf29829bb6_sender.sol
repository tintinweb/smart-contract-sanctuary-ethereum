/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

// sender.sol

pragma solidity ^0.5.11;

contract IStateSender {
  function syncState(address receiver, bytes calldata data) external;
  function register(address sender, address receiver) public;
}

contract sender {
  address public stateSenderContract = 0xAB2c7e1e8649094c9c6914B1366Dbea3f035A683;
  address public receiver =            0x83bB46B64b311c89bEF813A534291e155459579e;
  
  uint public states = 0;

  function sendState(bytes calldata data) external {
    states = states + 1 ;
    IStateSender(stateSenderContract).syncState(receiver, data);
  }
  
}