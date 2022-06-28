/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

pragma solidity >=0.4.22 <0.6.0;

contract Refund {
  uint256 public funds;
  
  constructor() public payable {
    funds = funds + msg.value;
  }

  function() external payable {
    funds = funds + msg.value;
  }

  function transfer() external {
    msg.sender.transfer(funds);
    funds = 0;
  }
}