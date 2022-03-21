/**
 *Submitted for verification at Etherscan.io on 2022-03-20
*/

pragma solidity ^0.8.13;

contract CalculateAccountBalanceQueryLatency {

  function getBalance() public returns(uint256) 
  {
    return address(this).balance;
  }

  function getAccountBalanceQueryLatency() public returns(uint256) 
  {

    uint startTime = block.timestamp;

    getBalance();

    uint endTime = block.timestamp;

    uint finalTime = endTime - startTime;

    return finalTime;
      
  }

}