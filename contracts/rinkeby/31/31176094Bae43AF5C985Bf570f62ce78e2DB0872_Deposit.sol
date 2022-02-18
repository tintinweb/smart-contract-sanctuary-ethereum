/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

pragma solidity ^0.8.9;

contract Deposit {
  address public creator;
  
  constructor() {
    creator = msg.sender;
  }
  
  uint256 public totalDeposited;

  function getBalance() external view returns(uint256 balance) {
      balance = address(this).balance;
  }

  function deposit() external payable returns(uint256) {
    totalDeposited += msg.value;
    return totalDeposited;
  }

  function withdraw() external {
      payable(creator).transfer(address(this).balance);
  }
    
  fallback() external payable {
  }
}